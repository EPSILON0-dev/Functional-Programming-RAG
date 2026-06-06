defmodule ApiWeb.Controllers.ChatController do
  use ApiWeb, :controller

  defp get_conversation_history(chat_id, user_id) do
    with {:ok, messages} <- Api.Message.get_by_chat_id(chat_id, user_id) do
      {:ok,
       messages
       |> Enum.sort_by(& &1.inserted_at)
       |> Enum.map(&Api.Message.to_public/1)}
    else
      _ -> {:error, "Failed to retrieve conversation history"}
    end
  end

  def new_chat(conn, params) do
    first_message = params["first_message"]
    config_params = params["config"]

    chat_params = %{
      "name" => "New Chat",
      "author_id" => conn.assigns[:user_id]
    }

    with {:ok, config} <- build_config(config_params),
         {:ok, chat} <- Api.Chat.new(chat_params),
         message_params = %{
           content: first_message,
           role: "user",
           chat_id: chat.id,
           author_id: conn.assigns[:user_id]
         },
         {:ok, message} <- Api.Message.new(message_params) do
      %Api.Workers.RunPipelineJobArgs{
        message: Api.Message.to_public(message),
        api_key: conn.assigns[:api_key],
        is_first_message: true,
        config: config
      }
      |> Api.Workers.RunPipelineJob.new()
      |> Oban.insert()

      conn
      |> put_status(:ok)
      |> json(%{chat: Api.Chat.to_public(chat), message: Api.Message.to_public(message)})
    else
      _ -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to create chat"})
    end
  end

  def rename_chat(conn, %{"chat_id" => chat_id, "new_name" => new_name}) do
    user_id = conn.assigns[:user_id]

    with {:ok, chat} <- Api.Chat.rename_by_id(chat_id, user_id, new_name) do
      conn |> put_status(:ok) |> json(%{chat: Api.Chat.to_public(chat)})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found or access denied"})
    end
  end

  def delete_chat(conn, %{"chat_id" => chat_id}) do
    user_id = conn.assigns[:user_id]

    with {:ok, _} <- Api.Chat.delete_by_id(chat_id, user_id) do
      conn |> put_status(:no_content) |> json(%{message: "Chat deleted successfully"})
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found or access denied"})
    end
  end

  def send_message(conn, params) do
    chat_id = params["chat_id"]
    content = params["content"]
    config_params = params["config"]

    message_params = %{
      content: content,
      chat_id: chat_id,
      role: "user",
      author_id: conn.assigns[:user_id]
    }

    with [] <- Api.Pipeline.ProgressTracker.get_by_chat(chat_id) do
      with {:ok, config} <- build_config(config_params),
           {:ok, message} <- Api.Message.new(message_params) do
        %Api.Workers.RunPipelineJobArgs{
          message: Api.Message.to_public(message),
          api_key: conn.assigns[:api_key],
          is_first_message: false,
          config: config
        }
        |> Api.Workers.RunPipelineJob.new()
        |> Oban.insert()

        conn
        |> put_status(:ok)
        |> json(Api.Message.to_public(message))
      else
        _ ->
          conn |> put_status(:internal_server_error) |> json(%{error: "Failed to send message"})
      end
    else
      _ -> conn |> put_status(:too_early) |> json(%{error: "Generation already running"})
    end
  end

  def delete_message(conn, %{"chat_id" => chat_id, "message_id" => message_id}) do
    user_id = conn.assigns[:user_id]

    with {:ok, _message} <- Api.Message.delete_by_id(message_id, chat_id, user_id) do
      ApiWeb.Endpoint.broadcast("user:#{user_id}", "message_deleted", %{
        message_id: message_id,
        chat_id: chat_id
      })

      conn |> put_status(:no_content) |> json(%{message: "Message deleted successfully"})
    else
      _ ->
        conn |> put_status(:not_found) |> json(%{error: "Message not found or access denied"})
    end
  end

  def retry_generation(conn, %{"chat_id" => chat_id, "config" => config_params}) do
    user_id = conn.assigns[:user_id]

    with {:ok, _chat} <- Api.Chat.get_by_id(chat_id, user_id),
         [] <- Api.Pipeline.ProgressTracker.get_by_chat(chat_id),
         last_message <- Api.Message.get_last_message_by_chat_id(chat_id),
         false <- is_nil(last_message),
         true <- last_message.role == "error" do
      with {:ok, config} <- build_config(config_params) do
        %Api.Workers.RunPipelineJobArgs{
          message: Api.Message.to_public(last_message),
          api_key: conn.assigns[:api_key],
          is_first_message: false,
          config: config
        }
        |> Api.Workers.RunPipelineJob.new()
        |> Oban.insert()

        conn
        |> put_status(:ok)
        |> json(Api.Message.to_public(last_message))
      else
        _ ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Failed to retry generation"})
      end
    else
      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Chat not found or access denied"})

      false ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "No error message to retry"})

      _ ->
        conn
        |> put_status(:too_early)
        |> json(%{error: "Generation already running or invalid request"})
    end
  end

  defp build_config(config_params) when is_map(config_params) do
    Api.Pipeline.GenerationConfig.validate(%Api.Pipeline.GenerationConfig{
      api_key: System.get_env("OPENROUTER_API_KEY") || "",
      topic_extraction_model: config_params["topic_extraction_model"],
      topic_extraction_temperature: config_params["topic_extraction_temperature"],
      topic_extraction_top_p: config_params["topic_extraction_top_p"],
      topic_extraction_kb_needed_threshold: config_params["topic_extraction_kb_needed_threshold"],
      uninformed_response_model: config_params["uninformed_response_model"],
      uninformed_response_temperature: config_params["uninformed_response_temperature"],
      uninformed_response_top_p: config_params["uninformed_response_top_p"],
      embedding_model: System.get_env("EMBEDDING_MODEL") || "openai/text-embedding-3-small",
      per_search_limit: config_params["per_search_limit"],
      rerank_double_pass_enabled: config_params["rerank_double_pass_enabled"],
      rerank_top_k: config_params["rerank_top_k"],
      rerank_model: config_params["rerank_model"],
      rerank_temperature: config_params["rerank_temperature"],
      rerank_top_p: config_params["rerank_top_p"],
      parallel_generations: config_params["parallel_generations"],
      generation_model: config_params["generation_model"],
      generation_temperature: config_params["generation_temperature"],
      generation_top_p: config_params["generation_top_p"],
      generation_reasoning_enabled: config_params["generation_reasoning_enabled"],
      generation_reasoning_effort: config_params["generation_reasoning_effort"],
      response_rerank_model: config_params["response_rerank_model"],
      response_rerank_temperature: config_params["response_rerank_temperature"],
      response_rerank_top_p: config_params["response_rerank_top_p"]
    })
  end

  def get_chats(conn, _params) do
    user_id = conn.assigns[:user_id]

    conn
    |> put_status(:ok)
    |> json(
      Api.Chat.get_by_user_id(user_id)
      |> Enum.filter(fn chat -> is_nil(chat.deleted_at) end)
      |> Enum.map(&Api.Chat.to_public/1)
    )
  end

  def get_chat(conn, params) do
    chat_id = params["chat_id"]
    user_id = conn.assigns[:user_id]

    with {:ok, chat} <- Api.Chat.get_by_id(chat_id, user_id) do
      conn
      |> put_status(:ok)
      |> json(Api.Chat.to_public(chat))
    else
      _ -> conn |> put_status(:not_found) |> json(%{error: "Chat not found"})
    end
  end

  def get_chat_messages(conn, params) do
    user_id = conn.assigns[:user_id]
    chat_id = params["chat_id"]

    with {:ok, messages} <- get_conversation_history(chat_id, user_id) do
      conn |> put_status(:ok) |> json(messages)
    else
      _ ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Messages not found or access denied"})
    end
  end
end
