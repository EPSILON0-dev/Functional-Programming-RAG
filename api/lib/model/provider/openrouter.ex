defmodule Model.Provider.OpenRouter do
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

  defp extract_reasoning_from_content(reasoning) do
    try do
      {:ok,
       reasoning["content"]
       |> Enum.filter(fn item -> item["type"] == "reasoning_text" end)
       |> List.first()
       |> Map.get("text")}
    rescue
      _ -> {:error, "Unable to extract reasoning text from response"}
    end
  end

  defp extract_reasoning_from_summary(reasoning) do
    try do
      {:ok,
       reasoning["summary"]
       |> Enum.filter(fn item -> item["type"] == "summary_text" end)
       |> List.first()
       |> Map.get("text")}
    rescue
      _ -> {:error, "Unable to extract reasoning text from response"}
    end
  end

  defp extract_responses_reasoning(response) do
    reasoning =
      response
      |> Map.get("output")
      |> Enum.filter(fn item -> item["type"] == "reasoning" end)
      |> List.first()

    # Try to extract reasoning text using both styles
    reasoning_text =
      case extract_reasoning_from_content(reasoning) do
        {:ok, text} ->
          text

        {:error, _} ->
          case extract_reasoning_from_summary(reasoning) do
            {:ok, text} -> text
            {:error, _} -> ""
          end
      end

    reasoning_text
  end

  defp extract_responses_metadata(response) do
    %Model.Provider.Metadata{
      # Request ID
      id: response["id"],

      # Token usage details
      input_tokens: response["usage"]["input_tokens"] || 0,
      cached_tokens: response["usage"]["input_tokens_details"]["cached_tokens"] || 0,
      reasoning_tokens: response["usage"]["output_tokens_details"]["reasoning_tokens"] || 0,
      output_tokens: response["usage"]["output_tokens"] || 0,
      total_tokens: response["usage"]["total_tokens"] || 0,

      # Cost details
      input_cost: response["usage"]["cost_details"]["upstream_inference_input_cost"] || 0.0,
      output_cost: response["usage"]["cost_details"]["upstream_inference_output_cost"] || 0.0,
      total_cost: response["usage"]["cost"] || 0.0,
      cost_currency: "USD",

      # Model and provider details
      provider: "OpenRouter",
      model: response["model"] || "",
      provider_model: response["model"] || "",

      # Generation parameters
      temperature: response["temperature"] || 0.0,
      top_p: response["top_p"] || 0.0,
      top_k: response["top_k"] || 0,
      presence_penalty: response["presence_penalty"] || 0.0,
      frequency_penalty: response["frequency_penalty"] || 0.0,

      # Reasoning parameters
      reasoning_enabled: response["reasoning"]["enabled"] || false,
      reasoning_effort: response["reasoning"]["effort"] || ""
    }
  end

  defp construct_response_query(options, prompt) do
    reasoning_map = %{
      "enabled" => options.reasoning_enabled || false,
      "effort" => options.reasoning_effort || "none"
    }

    Map.merge(Map.from_struct(options), %{"reasoning" => reasoning_map, "input" => prompt})
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
    |> Enum.filter(fn {k, _v} -> k != "reasoning_enabled" && k != "reasoning_effort" end)
    |> Enum.into(%{})
  end

  @doc """
    Queries OpenRouter for a response based on the given options and prompt using the response API.
    Returns {:ok, response} on success or {:error, reason} on failure.
  """
  @spec generate_response(String.t(), String.t(), Model.Provider.Options.t()) ::
          {:ok, Model.Provider.Response.t()} | {:error, String.t()}
  def generate_response(key, prompt, options, base_url \\ nil) do
    # TODO Load the API URL from config and support multiple environments
    openrouter_api_url = System.get_env("OPENROUTER_API_URL") || "https://openrouter.ai/api/v1"
    url = (base_url || openrouter_api_url) <> "/responses"
    headers = [Authorization: "Bearer " <> key, "Content-Type": "application/json"]
    params = construct_response_query(options, prompt)

    IO.inspect(headers, label: "OpenRouter Headers")
    IO.inspect(params, label: "OpenRouter Query Params")

    with {:ok, resp} <- Req.post(url: url, headers: headers, json: params) do
      case resp.status do
        200 ->
          if resp.body["status"] == "completed" do
            IO.inspect(resp.body, label: "OpenRouter Response Body")

            {:ok,
             %Model.Provider.Response{
               content: extract_responses_content(resp.body),
               reasoning: extract_responses_reasoning(resp.body),
               metadata: %{extract_responses_metadata(resp.body) | model: options.model}
             }}
          else
            {:error, resp.body["error"] || "OpenRouter response failed"}
          end

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

# Model.Provider.OpenRouter.query_response
