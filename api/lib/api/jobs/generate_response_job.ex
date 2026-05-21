defmodule Api.Workers.GenerateResponseJob do
  use Oban.Worker,
    queue: :default,
    max_attempts: 1

  defp broadcast_generating_response(initial_message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_new", %{
      id: initial_message.id,
      role: initial_message.role,
      chat_id: initial_message.chat_id,
      timestamp: initial_message.inserted_at
    })
  end

  defp create_initial_message(args) do
    with {:ok, initial_message} <-
           Api.Message.new(%{
             "content" => "",
             "role" => "generating",
             "chat_id" => args["chat_id"],
             "author_id" => nil
           }),
         broadcast_generating_response(initial_message, args["author_id"]) do
      {:ok, initial_message}
    else
      _ -> {:error, "Failed to create initial message"}
    end
  end

  defp get_conversation(chat_id, user_id) do
    with {:ok, messages} <- Api.Message.get_by_chat_id(chat_id, user_id) do
      {:ok,
       messages
       |> Enum.filter(fn message -> message.role in ["user", "assistant"] end)
       |> Enum.sort_by(& &1.inserted_at)
       |> Enum.map(
         &%{
           role: &1.role,
           content: &1.content
         }
       )}
    else
      _ -> {:error, "Failed to retrieve conversation history"}
    end
  end

  defp generate_response(api_key, message) do
    with {:ok, conversation} <- get_conversation(message["chat_id"], message["author_id"]) do
      options = %Model.Provider.Options{model: "gpt-4o"}

      case Model.Provider.OpenRouter.generate_response(api_key, conversation, options) do
        {:ok, response} -> {:ok, response}
        {:error, reason} -> {:error, reason}
      end
    else
      _ ->
        {:error, "Failed to generate response from OpenRouter"}
    end
  end

  defp broadcast_response_complete(complete_message, user_id) do
    ApiWeb.Endpoint.broadcast("user:#{user_id}", "response_complete", %{
      id: complete_message.id,
      role: complete_message.role,
      content: complete_message.content,
      chat_id: complete_message.chat_id,
      timestamp: complete_message.inserted_at
    })
  end

  defp handle_completion(response, message_id, user_id) do
    message = %{
      content: response.content,
      metadata:
        Map.merge(Map.from_struct(response.metadata), %{
          "reasoning" => response.reasoning
        }),
      role: "assistant"
    }

    with {:ok, complete_message} <- Api.Message.update_by_id(message_id, message) do
      broadcast_response_complete(complete_message, user_id)
    end
  end

  defp handle_error(reason, message_id, user_id) do
    with {:ok, complete_message} <-
           Api.Message.update_by_id(message_id, %{
             content: "An error occurred while generating the response.",
             role: "error"
           }) do
      broadcast_response_complete(complete_message, user_id)
    end

    {:error, reason}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    #
    # Step 1: Create initial message with role "generating" and broadcast to user
    with {:ok, initial_message} <- create_initial_message(args["message"]) do
      #
      # Step 2: Generate response from OpenRouter using conversation history as context
      with {:ok, response} <- generate_response(args["api_key"], args["message"]) do
        #
        # Step 3: Update initial message with generated content and broadcast completion to user
        handle_completion(response, initial_message.id, args["message"]["author_id"])

        # Step 4: If it was the first message start the job for renaming the chat
        if args["is_first_message"] do
          %Api.Workers.GenerateTitleJobArgs{
            chat_id: args["message"]["chat_id"],
            user_id: args["message"]["author_id"],
            api_key: args["api_key"]
          }
          |> Api.Workers.GenerateTitleJob.new()
          |> Oban.insert()
        end

        {:ok, "Response generated successfully"}
      else
        #
        # Step 3*: If generation failed update the message with an error and broadcast to user
        {_, reason} ->
          handle_error(reason, initial_message.id, args["message"]["author_id"])
          {:error, reason}
      end
    else
      {_, reason} ->
        {:error, reason}
    end
  end
end
