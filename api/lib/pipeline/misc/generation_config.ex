defmodule Api.Pipeline.GenerationConfig do
  @max_parallel_generations 5
  @max_per_search_limit 50

  @derive Jason.Encoder
  defstruct [
    # API Configuration
    api_key: System.get_env("OPENROUTER_API_KEY") || "",

    # Stage 1: Topic Extraction
    topic_extraction_model: "openai/gpt-4.1-mini",
    topic_extraction_temperature: 0.1,
    topic_extraction_top_p: 0.9,
    topic_extraction_kb_needed_threshold: 0.5,

    # Stage 2: Uninformed Response
    uninformed_response_model: "openai/gpt-4.1",
    uninformed_response_temperature: 0.7,
    uninformed_response_top_p: 0.95,

    # Stage 3: Embedding Retrieval
    embedding_model: System.get_env("EMBEDDING_MODEL") || "openai/text-embedding-3-small",
    per_search_limit: 10,

    # Stage 4: Rerank Stage
    rerank_double_pass_enabled: true,
    rerank_top_k: 10,
    rerank_model: "openai/gpt-4.1-mini",
    rerank_temperature: 0.0,
    rerank_top_p: 1.0,

    # Stage 5: Generation
    parallel_generations: 2,
    generation_model: "openai/gpt-4.1",
    generation_temperature: 0.7,
    generation_top_p: 0.95,
    generation_reasoning_enabled: true,
    generation_reasoning_effort: "low",

    # Stage 6: Response Rerank
    response_rerank_model: "openai/gpt-4.1-mini",
    response_rerank_temperature: 0.0,
    response_rerank_top_p: 1.0
  ]

  @type t :: %__MODULE__{
          api_key: String.t(),
          topic_extraction_model: String.t(),
          topic_extraction_temperature: float(),
          topic_extraction_top_p: float(),
          topic_extraction_kb_needed_threshold: float(),
          uninformed_response_model: String.t(),
          uninformed_response_temperature: float(),
          uninformed_response_top_p: float(),
          embedding_model: String.t(),
          per_search_limit: non_neg_integer(),
          rerank_double_pass_enabled: boolean(),
          rerank_top_k: non_neg_integer(),
          rerank_model: String.t(),
          rerank_temperature: float(),
          rerank_top_p: float(),
          parallel_generations: non_neg_integer(),
          generation_model: String.t(),
          generation_temperature: float(),
          generation_top_p: float(),
          generation_reasoning_enabled: boolean(),
          generation_reasoning_effort: String.t(),
          response_rerank_model: String.t(),
          response_rerank_temperature: float(),
          response_rerank_top_p: float()
        }

  defp clamp(value, min, max) when is_number(value) and is_number(min) and is_number(max) do
    value
    |> max(min)
    |> min(max)
  end

  def validate(config) do
    with true <- is_binary(config.api_key) and config.api_key != "",
         true <- is_binary(config.topic_extraction_model) and config.topic_extraction_model != "",
         true <-
           is_binary(config.uninformed_response_model) and config.uninformed_response_model != "",
         true <- is_binary(config.embedding_model) and config.embedding_model != "",
         true <- is_binary(config.rerank_model) and config.rerank_model != "",
         true <- is_binary(config.generation_model) and config.generation_model != "",
         true <- is_binary(config.response_rerank_model) and config.response_rerank_model != "" do
      config =
        config
        |> Map.update!(:parallel_generations, &clamp(&1, 1, @max_parallel_generations))
        |> Map.update!(:per_search_limit, &clamp(&1, 1, @max_per_search_limit))
        |> Map.update!(:topic_extraction_temperature, &clamp(&1, 0.0, 2.0))
        |> Map.update!(:topic_extraction_top_p, &clamp(&1, 0.0, 1.0))
        |> Map.update!(:topic_extraction_kb_needed_threshold, &clamp(&1, 0.0, 1.0))
        |> Map.update!(:uninformed_response_temperature, &clamp(&1, 0.0, 2.0))
        |> Map.update!(:uninformed_response_top_p, &clamp(&1, 0.0, 1.0))
        |> Map.update!(:rerank_top_k, &clamp(&1, 0, @max_per_search_limit))
        |> Map.update!(:rerank_temperature, &clamp(&1, 0.0, 2.0))
        |> Map.update!(:rerank_top_p, &clamp(&1, 0.0, 1.0))
        |> Map.update!(:generation_temperature, &clamp(&1, 0.0, 2.0))
        |> Map.update!(:generation_top_p, &clamp(&1, 0.0, 1.0))
        |> Map.update!(:response_rerank_temperature, &clamp(&1, 0.0, 2.0))
        |> Map.update!(:response_rerank_top_p, &clamp(&1, 0.0, 1.0))

      {:ok, config}
    else
      _ -> {:error, :invalid_config}
    end
  end
end
