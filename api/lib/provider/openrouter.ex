defmodule Api.Provider.OpenRouter do
  # Extractors for /chat/completions endpoint
  defp extract_chat_content(response) do
    response
    |> Map.get("choices")
    |> Enum.filter(fn item -> item["message"]["role"] == "assistant" end)
    |> List.first()
    |> Map.get("message")
    |> Map.get("content")
  end

  defp extract_chat_reasoning(response) do
    response
    |> Map.get("choices")
    |> Enum.filter(fn item -> item["message"]["role"] == "assistant" end)
    |> List.first()
    |> Map.get("message")
    |> Map.get("reasoning")
  end

  defp extract_chat_metadata(response) do
    %Api.Provider.Metadata{
      # Request ID
      id: response["id"],

      # Token usage details
      input_tokens: response["usage"]["prompt_tokens"] || 0,
      output_tokens: response["usage"]["completion_tokens"] || 0,
      total_tokens: response["usage"]["total_tokens"] || 0,

      # Cost details
      input_cost: response["usage"]["cost_details"]["upstream_inference_prompt_cost"] || 0.0,
      output_cost: response["usage"]["cost_details"]["upstream_inference_completion_cost"] || 0.0,
      total_cost: response["usage"]["cost"] || 0.0,

      # Model and provider details
      provider: response["provider"] || "unknown",
      model: response["model"] || "",
      provider_model: response["model"] || ""
    }
  end

  # Extractors for /responses endpoint
  defp extract_responses_content(response) do
    response
    |> Map.get("output")
    |> Enum.filter(fn item -> item["type"] == "message" end)
    |> List.first()
    |> Map.get("content")
    |> Enum.filter(fn item -> item["type"] == "output_text" end)
    |> List.first()
    |> Map.get("text")
  end

  defp extract_responses_reasoning(_) do
    ""
  end

  defp extract_responses_metadata(response) do
    %Api.Provider.Metadata{
      # Request ID
      id: response["id"],

      # Token usage details
      input_tokens: response["usage"]["input_tokens"] || 0,
      output_tokens: response["usage"]["output_tokens"] || 0,
      total_tokens: response["usage"]["total_tokens"] || 0,

      # Cost details
      input_cost: response["usage"]["cost_details"]["upstream_inference_input_cost"] || 0.0,
      output_cost: response["usage"]["cost_details"]["upstream_inference_output_cost"] || 0.0,
      total_cost: response["usage"]["cost"] || 0.0,

      # Model and provider details
      provider: response["provider"] || "unknown",
      model: response["model"] || "",
      provider_model: response["model"] || ""
    }
  end

  defp construct_query(options, input, type) do
    reasoning_map = %{
      "reasoning" => %{
        "enabled" => options.reasoning_enabled || false,
        "effort" => options.reasoning_effort || "none"
      }
    }

    format_map =
      if options.format do
        %{
          "text" => %{
            "format" => options.format
          }
        }
      else
        %{}
      end

    input_map =
      case type do
        :chat -> %{"messages" => input}
        :response -> %{"input" => input}
      end

    final_map =
      Map.from_struct(options)
      |> Map.merge(input_map)
      |> Map.merge(reasoning_map)
      |> Map.merge(format_map)
      |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
      |> Enum.filter(fn {k, _v} ->
        k != "reasoning_enabled" && k != "reasoning_effort" && k != "format"
      end)
      |> Enum.into(%{})

    # IO.inspect(final_map, label: "Constructing OpenRouter Query with Conversation")
    final_map
  end

  defp extract_embedding_response(response) do
    %Api.Provider.Embedding{
      embedding: response |> Map.get("data") |> List.first() |> Map.get("embedding"),
      tokens: response |> Map.get("usage") |> Map.get("total_tokens"),
      cost: response |> Map.get("usage") |> Map.get("cost")
    }
  end

  @doc """
    Queries OpenRouter for a response based on the given options and conversation using the /chat/completions endpoint.
    Returns {:ok, response} on success or {:error, reason} on failure.
  """
  @spec generate_chat_completion(String.t(), String.t(), Api.Provider.Options.t()) ::
          {:ok, Api.Provider.Response.t()} | {:error, String.t()}
  def generate_chat_completion(key, conversation, options, base_url \\ nil) do
    openrouter_api_url = System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    url = (base_url || openrouter_api_url) <> "/chat/completions"
    headers = [Authorization: "Bearer " <> key, "Content-Type": "application/json"]
    params = construct_query(options, conversation, :chat)

    # IO.inspect(headers, label: "OpenRouter Headers")
    # IO.inspect(params, label: "OpenRouter Query Params")

    with {:ok, resp} <- Req.post(url: url, headers: headers, json: params, finch: Api.Finch) do
      case resp.status do
        200 ->
          # IO.inspect(resp.body, label: "OpenRouter Response Body")

          {:ok,
           %Api.Provider.Response{
             content: extract_chat_content(resp.body),
             reasoning: extract_chat_reasoning(resp.body),
             metadata: %{extract_chat_metadata(resp.body) | model: options.model}
           }}

        401 ->
          {:error, resp.body["error"] || "Unauthorized: Invalid API key"}

        _ ->
          {:error, resp.body["error"] || "OpenRouter API returned status #{resp.status}"}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Queries OpenRouter for responses based on the given options and conversation using the /responses endpoint.
    Returns {:ok, response} on success or {:error, reason} on failure.
  """
  @spec generate_response(String.t(), String.t(), Api.Provider.Options.t()) ::
          {:ok, Api.Provider.Response.t()} | {:error, String.t()}
  def generate_response(key, input, options, base_url \\ nil) do
    openrouter_api_url = System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    url = (base_url || openrouter_api_url) <> "/responses"
    headers = [Authorization: "Bearer " <> key, "Content-Type": "application/json"]
    params = construct_query(options, input, :response)

    # IO.inspect(headers, label: "OpenRouter Headers")
    # IO.inspect(params, label: "OpenRouter Query Params")

    with {:ok, resp} <- Req.post(url: url, headers: headers, json: params, finch: Api.Finch) do
      case resp.status do
        200 ->
          # IO.inspect(resp.body, label: "OpenRouter Response Body")

          {:ok,
           %Api.Provider.Response{
             content: extract_responses_content(resp.body),
             reasoning: extract_responses_reasoning(resp.body),
             metadata: %{extract_responses_metadata(resp.body) | model: options.model}
           }}

        401 ->
          {:error, resp.body["error"] || "Unauthorized: Invalid API key"}

        _ ->
          {:error, resp.body["error"] || "OpenRouter API returned status #{resp.status}"}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Queries OpenRouter for an embedding based on the given input and model.
    Returns {:ok, embedding} on success or {:error, reason} on failure.
  """
  @spec generate_embedding(
          String.t(),
          String.t(),
          String.t(),
          non_neg_integer() | nil,
          String.t() | nil
        ) ::
          {:ok, Api.Provider.Embedding.t()} | {:error, String.t()}
  def generate_embedding(key, input, model, dimensions \\ nil, base_url \\ nil) do
    openrouter_api_url = System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    url = (base_url || openrouter_api_url) <> "/embeddings"
    headers = [Authorization: "Bearer " <> key, "Content-Type": "application/json"]

    params =
      %{
        model: model,
        input: input,
        dimensions: dimensions
      }
      |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
      |> Enum.into(%{})

    with {:ok, resp} <- Req.post(url: url, headers: headers, json: params, finch: Api.Finch) do
      case resp.status do
        200 ->
          {:ok, extract_embedding_response(resp.body)}

        401 ->
          {:error, resp.body["error"] || "Unauthorized: Invalid API key"}

        _ ->
          {:error, resp.body["error"] || "OpenRouter API returned status #{resp.status}"}
      end
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
