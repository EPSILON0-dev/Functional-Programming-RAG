defmodule Model.Provider.OpenRouter do
  defp extract_responses_content(response) do
    response
    |> Map.get("choices")
    |> Enum.filter(fn item -> item["message"]["role"] == "assistant" end)
    |> List.first()
    |> Map.get("message")
    |> Map.get("content")
  end

  defp extract_responses_reasoning(response) do
    response
    |> Map.get("choices")
    |> Enum.filter(fn item -> item["message"]["role"] == "assistant" end)
    |> List.first()
    |> Map.get("message")
    |> Map.get("reasoning")
  end

  defp extract_responses_metadata(response) do
    %Model.Provider.Metadata{
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
      provider_model: response["model"] || "",
    }
  end

  defp construct_response_query(options, conversation) do
    reasoning_map = %{
      "enabled" => options.reasoning_enabled || false,
      "effort" => options.reasoning_effort || "none"
    }

    final_map =
      Map.merge(Map.from_struct(options), %{
        "reasoning" => reasoning_map,
        "messages" => conversation
      })
      |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
      |> Enum.filter(fn {k, _v} -> k != "reasoning_enabled" && k != "reasoning_effort" end)
      |> Enum.into(%{})

    # IO.inspect(final_map, label: "Constructing OpenRouter Query with Conversation")
    final_map
  end

  @doc """
    Queries OpenRouter for a response based on the given options and conversation using the response API.
    Returns {:ok, response} on success or {:error, reason} on failure.
  """
  @spec generate_response(String.t(), String.t(), Model.Provider.Options.t()) ::
          {:ok, Model.Provider.Response.t()} | {:error, String.t()}
  def generate_response(key, conversation, options, base_url \\ nil) do
    openrouter_api_url = System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    url = (base_url || openrouter_api_url) <> "/chat/completions"
    headers = [Authorization: "Bearer " <> key, "Content-Type": "application/json"]
    params = construct_response_query(options, conversation)

    # IO.inspect(headers, label: "OpenRouter Headers")
    # IO.inspect(params, label: "OpenRouter Query Params")

    with {:ok, resp} <- Req.post(url: url, headers: headers, json: params) do
      case resp.status do
        200 ->
          # IO.inspect(resp.body, label: "OpenRouter Response Body")

          {:ok,
           %Model.Provider.Response{
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
end
