defmodule Api.Pipeline.CreateArticle do
  @normalization_prompt """
  You are a helpful assistant for normalizing and chunking documents to be stored in a knowledge base.
  Your task is to take the provided text and perform the following operations:
   * Normalize the text by removing any irrelevant information,
      correcting formatting issues, and ensuring consistency in style.
   * Make sure the normalized text is written in ENGLISH, regardless of the input language.
   * Assess the relevance of the text to the knowledge base, providing a
      relevance score between 0 and 1, where 0 means completely irrelevant
      and 1 means highly relevant. Also provide a brief explanation for the
      assigned relevance score.
  Notes:
   * Documents containing useful information for the knowledge base should be prioritized.
   * Documents containing information like: tables of content, indexes, references, author
       information, publication details, etc. should be considered less relevant.
  """

  @normalization_output_format %{
    name: "text_normalization_schema",
    schema: %{
      properties: %{
        normalized_article: %{
          type: "string",
          description:
            "Normalized version of the input text, with irrelevant information removed and formatting issues corrected."
        },
        relevance_score: %{
          type: "string",
          description:
            "Relevance score of the input text to the knowledge base, ranging from 0 (completely irrelevant) to 1 (highly relevant) as float."
        },
        relevance_reason: %{
          type: "string",
          description: "Explanation for the assigned relevance score."
        }
      },
      type: "object",
      required: [
        "normalized_article",
        "relevance_score",
        "relevance_reason"
      ],
      additionalProperties: false
    },
    type: "json_schema"
  }

  @title_description_prompt """
  You are a helpful assistant for generating titles and descriptions for documents to be stored in a knowledge base.
  Your task is to take the provided text and perform the following operations:
   * Generate a concise and informative title for the text.
   * Generate a brief description that summarizes the main points of the text.
  Notes:
   * The title should be clear and relevant to the content of the text.
   * The description should provide a quick overview of the text's content.
   * The title should be at most 10 words long, and the description should be at most 50 words or 2 sentences long.
   * Make sure the title and the description are written in ENGLISH, regardless of the input language.
  """

  @title_description_output_format %{
    name: "title_description_schema",
    schema: %{
      properties: %{
        title: %{
          type: "string",
          description: "Generated title for the input text."
        },
        description: %{
          type: "string",
          description: "Generated description summarizing the main points of the input text."
        }
      },
      type: "object",
      required: ["title", "description"],
      additionalProperties: false
    },
    type: "json_schema"
  }

  @generation_options %Api.Provider.Options{
    temperature: 0.1,
    top_p: 0.9,
    presence_penalty: 0.0,
    frequency_penalty: 0.0,
    reasoning_enabled: true,
    reasoning_effort: "medium"
  }

  defp normalize_and_assess(text) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    model = Application.get_env(:api, Api.Loader)[:llm_model] || "openai/gpt-5-mini"

    options = %Api.Provider.Options{
      @generation_options
      | model: model,
        format: @normalization_output_format
    }

    input = text <> "\n\n\n" <> @normalization_prompt

    case Api.Provider.OpenRouter.generate_response(key, input, options) do
      {:ok, response} ->
        {:ok, Jason.decode!(response.content), response.metadata.total_cost}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp generate_title(text) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    model = Application.get_env(:api, Api.Loader)[:llm_model] || "openai/gpt-5-mini"

    options = %Api.Provider.Options{
      @generation_options
      | model: model,
        format: @title_description_output_format
    }

    input = text <> "\n\n\n" <> @title_description_prompt

    case Api.Provider.OpenRouter.generate_response(key, input, options) do
      {:ok, response} ->
        {:ok, Jason.decode!(response.content), response.metadata.total_cost}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def generate_embeddings(text) do
    key = System.get_env("OPENROUTER_API_KEY") || ""

    model =
      Application.get_env(:api, Api.Loader)[:embedding_model] || "openai/text-embedding-3-small"

    case Api.Provider.OpenRouter.generate_embedding(key, text, model) do
      {:ok, embedding} ->
        {:ok, embedding}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_article(chunk) do
    debug_enabled = Application.get_env(:api, Api.Loader)[:debug] || false

    embedding_model =
      Application.get_env(:api, Api.Loader)[:embedding_model] || "openai/text-embedding-3-small"

    minimal_relevance_score =
      Application.get_env(:api, Api.Loader)[:minimal_relevance_score] || 0.2

    with {:ok, normalized_chunk, normalization_cost} <- normalize_and_assess(chunk) do
      if normalized_chunk["relevance_score"] >= minimal_relevance_score do
        normalized_article = normalized_chunk["normalized_article"]

        with {:ok, title, titling_cost} <- generate_title(normalized_article),
             {:ok, description_embedding} <- generate_embeddings(title["description"]),
             {:ok, content_embedding} <- generate_embeddings(normalized_article) do
          total_cost =
            normalization_cost +
              titling_cost +
              description_embedding.cost +
              content_embedding.cost

          completed_article = %Api.Article{
            title: title["title"],
            description: title["description"],
            content: normalized_article,
            description_embedding: description_embedding.embedding,
            content_embedding: content_embedding.embedding,
            generation_cost: total_cost,
            embedding_model: embedding_model
          }

          if debug_enabled do
            IO.inspect(completed_article,
              label: "Generated Article",
              limit: :infinity,
              printable_limit: :infinity
            )
          end

          {:ok, completed_article}
        else
          {:error, reason} -> {:error, reason}
        end
      else
        {:dropped, normalized_chunk["relevance_reason"]}
      end
    end
  end
end
