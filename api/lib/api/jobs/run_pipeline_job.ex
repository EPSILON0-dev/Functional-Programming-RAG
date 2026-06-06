defmodule Api.Workers.RunPipelineJob do
  @moduledoc """
  Oban job that drives the 6-stage RAG pipeline for a single user question.

  Stages:
    1. TopicExtraction   — determines if KB lookup is needed, normalises query, extracts keywords
    2. UninformedResponse — generates a knowledge-free answer (used as HyDE seed or final answer)
    3. EmbeddingRetrieval — vector similarity search using the query + uninformed response
    4. RerankStage        — LLM-based relevance reranking with optional double-pass
    5. Generation         — parallel informed response generation using retrieved articles
    6. ResponseRerank     — picks the best candidate response

  If stage 1 determines that the knowledge base is not needed, the pipeline short-circuits
  after stage 2 and uses the uninformed response as the final answer.

  Progress is tracked in `Api.Pipeline.ProgressTracker` (ETS) and broadcast to the
  client via the `"user:\#{user_id}"` Phoenix channel as `pipeline_progress` events.
  Only two DB writes occur: one at job start (creating the "generating" message) and
  one at job end (finalising with the assistant response or error).
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  # ---------------------------------------------------------------------------
  # Oban entry point
  # ---------------------------------------------------------------------------

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    message_id = args["message"]["id"]
    chat_id = args["message"]["chat_id"]
    user_id = args["message"]["author_id"]
    question = args["message"]["content"]
    api_key = args["api_key"]
    is_first_message = args["is_first_message"]
    config_arg = args["config"]

    with {:ok, gen_message} <-
           Api.Message.new(%{
             "content" => "",
             "role" => "generating",
             "chat_id" => chat_id,
             "author_id" => nil
           }),
         {:ok, history} <- get_conversation_history(chat_id, user_id, message_id),
         {:ok, config} <-
           validate_config(config_arg, api_key) do
      Api.Pipeline.ProgressTracker.start_job(gen_message.id, chat_id, user_id)
      broadcast_response_new(gen_message, user_id)

      state = %Api.Workers.PipelineState{
        gen_id: gen_message.id,
        user_id: user_id,
        chat_id: chat_id,
        history: history,
        question: question,
        api_key: api_key,
        is_first_message: is_first_message,
        config: config
      }

      run_stage1(state)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Pipeline stages
  # ---------------------------------------------------------------------------

  defp run_stage1(state) do
    advance_stage(state, 1, "topic_extraction")

    case Api.Pipeline.TopicExtraction.run(state.history, state.question, state.config) do
      {:ok, topic} ->
        state = %{state | cost: state.cost + topic.cost, topic: topic}

        if topic.kb_needed do
          run_stage2(state)
        else
          run_stage2_short_circuit(state)
        end

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  # Stage 2 on the short-circuit path: the uninformed response IS the final answer.
  defp run_stage2_short_circuit(state) do
    advance_stage(state, 2, "uninformed_response")

    case Api.Pipeline.UninformedResponse.run(state.history, state.question, state.config) do
      {:ok, uninformed} ->
        finalize(state, uninformed.response, %{
          total_cost: state.cost + uninformed.cost,
          kb_used: false,
          kb_reason: state.topic.kb_reason,
          stages_completed: 2
        })

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  # Stage 2 on the full pipeline path: uninformed response seeds HyDE retrieval.
  defp run_stage2(state) do
    advance_stage(state, 2, "uninformed_response")

    case Api.Pipeline.UninformedResponse.run(state.history, state.question, state.config) do
      {:ok, uninformed} ->
        run_stage3(%{
          state
          | cost: state.cost + uninformed.cost,
            uninformed_response: uninformed.response
        })

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  defp run_stage3(state) do
    advance_stage(state, 3, "retrieval")

    case Api.Pipeline.EmbeddingRetrieval.run(
           state.question,
           state.uninformed_response,
           state.config
         ) do
      {:ok, articles, cost} ->
        run_stage4(%{state | cost: state.cost + cost, articles: articles})

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  defp run_stage4(state) do
    advance_stage(state, 4, "rerank")

    case Api.Pipeline.RerankStage.run(state.topic.normalized_query, state.articles, state.config) do
      {:ok, top_articles, cost} ->
        run_stage5(%{state | cost: state.cost + cost, top_articles: top_articles})

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  defp run_stage5(state) do
    advance_stage(state, 5, "generation")

    case Api.Pipeline.Generation.run(
           state.history,
           state.question,
           state.top_articles,
           state.config
         ) do
      {:ok, candidates, cost} ->
        run_stage6(%{state | cost: state.cost + cost, candidates: candidates})

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  defp run_stage6(state) do
    advance_stage(state, 6, "response_rerank")

    case Api.Pipeline.ResponseRerank.run(state.question, state.candidates, state.config) do
      {:ok, best} ->
        total_cost = state.cost + best.cost

        finalize(state, best.response, %{
          total_cost: total_cost,
          kb_used: true,
          articles_retrieved: length(state.articles),
          articles_used: length(state.top_articles),
          stages_completed: 6
        })

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  # ---------------------------------------------------------------------------
  # Finalisation and error handling
  # ---------------------------------------------------------------------------

  defp finalize(state, content, pipeline_meta) do
    # Build article info from top_articles if available
    article_info =
      if state.top_articles && state.top_articles != [] do
        Enum.map(state.top_articles, fn article ->
          %{
            id: article.id,
            title: article.title
          }
        end)
      else
        []
      end

    # Merge article info into metadata
    full_metadata = Map.put(pipeline_meta, :articles, article_info)

    case Api.Message.update_by_id(state.gen_id, %{
           content: content,
           author_id: state.user_id,
           role: "assistant",
           metadata: full_metadata
         }) do
      {:ok, message} ->
        Api.Pipeline.ProgressTracker.complete_job(state.gen_id)
        broadcast_response_complete(message, state.user_id)

        if state.is_first_message do
          %Api.Workers.GenerateTitleJobArgs{
            chat_id: state.chat_id,
            user_id: state.user_id,
            api_key: state.api_key
          }
          |> Api.Workers.GenerateTitleJob.new()
          |> Oban.insert()
        end

        {:ok, "Pipeline completed successfully"}

      {:error, reason} ->
        pipeline_error(state, reason)
    end
  end

  defp pipeline_error(state, reason) do
    case Api.Message.update_by_id(state.gen_id, %{
           content: "An error occurred while generating the response.",
           role: "error",
           author_id: state.user_id,
           metadata: %{"error" => inspect(reason)}
         }) do
      {:ok, message} -> broadcast_response_complete(message, state.user_id)
      _ -> :ok
    end

    Api.Pipeline.ProgressTracker.complete_job(state.gen_id)
    {:error, reason}
  end

  defp validate_config(nil, api_key) do
    config = %Api.Pipeline.GenerationConfig{api_key: api_key}
    Api.Pipeline.GenerationConfig.validate(config)
  end

  defp validate_config(config_map, api_key) when is_map(config_map) do
    config = %Api.Pipeline.GenerationConfig{
      api_key: api_key,
      topic_extraction_model:
        config_map["topic_extraction_model"] ||
          "openai/gpt-4.1-mini",
      topic_extraction_temperature: config_map["topic_extraction_temperature"] || 0.1,
      topic_extraction_top_p: config_map["topic_extraction_top_p"] || 0.9,
      topic_extraction_kb_needed_threshold:
        config_map["topic_extraction_kb_needed_threshold"] || 0.5,
      uninformed_response_model: config_map["uninformed_response_model"] || "openai/gpt-4.1",
      uninformed_response_temperature: config_map["uninformed_response_temperature"] || 0.7,
      uninformed_response_top_p: config_map["uninformed_response_top_p"] || 0.95,
      embedding_model: System.get_env("EMBEDDING_MODEL") || "openai/text-embedding-3-small",
      per_search_limit: config_map["per_search_limit"] || 10,
      rerank_double_pass_enabled: config_map["rerank_double_pass_enabled"] || true,
      rerank_top_k: config_map["rerank_top_k"] || 10,
      rerank_model: config_map["rerank_model"] || "openai/gpt-4.1-mini",
      rerank_temperature: config_map["rerank_temperature"] || 0.0,
      rerank_top_p: config_map["rerank_top_p"] || 1.0,
      parallel_generations: config_map["parallel_generations"] || 2,
      generation_model: config_map["generation_model"] || "openai/gpt-4.1",
      generation_temperature: config_map["generation_temperature"] || 0.7,
      generation_top_p: config_map["generation_top_p"] || 0.95,
      generation_reasoning_enabled: config_map["generation_reasoning_enabled"] || true,
      generation_reasoning_effort: config_map["generation_reasoning_effort"] || "low",
      response_rerank_model: config_map["response_rerank_model"] || "openai/gpt-4.1-mini",
      response_rerank_temperature: config_map["response_rerank_temperature"] || 0.0,
      response_rerank_top_p: config_map["response_rerank_top_p"] || 1.0
    }

    Api.Pipeline.GenerationConfig.validate(config)
  end

  defp validate_config(config = %Api.Pipeline.GenerationConfig{}, _api_key) do
    Api.Pipeline.GenerationConfig.validate(config)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  # Fetches all user/assistant messages for the chat, excluding the message
  # that triggered this job (it is passed as `question` separately).
  defp get_conversation_history(chat_id, user_id, current_message_id) do
    with {:ok, messages} <- Api.Message.get_by_chat_id(chat_id, user_id) do
      history =
        messages
        |> Enum.filter(fn m ->
          m.role in ["user", "assistant"] and m.id != current_message_id
        end)
        |> Enum.sort_by(& &1.inserted_at)
        |> Enum.map(&%{role: &1.role, content: &1.content})

      {:ok, history}
    end
  end

  # Updates ProgressTracker with the current accumulated cost and broadcasts
  # a pipeline_progress event. Called at the START of each stage.
  defp advance_stage(state, stage, stage_name) do
    Api.Pipeline.ProgressTracker.update_stage(
      state.gen_id,
      stage,
      stage_name,
      state.cost
    )

    case Api.Pipeline.ProgressTracker.to_progress_event(state.gen_id) do
      {:ok, payload} ->
        ApiWeb.Endpoint.broadcast("user:#{state.user_id}", "pipeline_progress", payload)

      _ ->
        :ok
    end
  end

  defp broadcast_response_new(message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_new", %{
      id: message.id,
      role: message.role,
      chat_id: message.chat_id,
      timestamp: message.inserted_at
    })
  end

  defp broadcast_response_complete(message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_complete", %{
      id: message.id,
      role: message.role,
      content: message.content,
      metadata: message.metadata,
      chat_id: message.chat_id,
      timestamp: message.inserted_at
    })
  end
end
