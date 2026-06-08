defmodule Api.Pipeline.CreateArticle do
  @normalization_prompt """
    You are preparing text chunks for a retrieval-augmented generation (RAG) knowledge base.

    Normalization rules:
    * Always write the output in English.
    * Preserve all factual and technical information.
    * Remove formatting artifacts, page numbers, headers, footers, OCR errors, and duplicated text.
    * Remove references to document structure such as:
      - introductions,
      - prefaces,
      - forewords,
      - tables of contents,
      - chapter summaries,
      - conclusions,
      - acknowledgements,
      - copyright notices,
      - indexes,
      - navigation instructions.
    * Do not add information that is not present in the input.
    * Do not begin with phrases like "This text", "The document", or similar.
    * Convert lists and fragmented sentences into coherent prose when appropriate.

    Relevance scoring:
    * 1.0: Dense factual or technical knowledge useful for future question answering.
    * 0.8: Mostly useful content with minor contextual material.
    * 0.5: Mixed content with substantial non-knowledge material.
    * 0.2: Mostly metadata, commentary, or document-specific navigation.
    * 0.0: Pure introduction, table of contents, summary, conclusion, legal notice, or other non-retrievable material.

    The relevance score should reflect the usefulness of storing this chunk in a knowledge base, not the quality of the writing.
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
    You are generating metadata for a document that will be stored in a retrieval-augmented generation (RAG) knowledge base.

    Requirements:
     * Output ONLY valid JSON. Do not include markdown or explanations.
     * The title must:
      - be in English,
      - contain at most 10 words,
      - describe the main subject of the document,
      - avoid generic prefixes like "Introduction to" or "Overview of" unless essential.
     * The description must:
      - be in English,
      - contain at most 50 words,
      - summarize the key topics and purpose of the document,
      - include important domain-specific terms that may improve retrieval,
      - avoid filler and subjective language.
     * Do not mention that this is a book, article, chapter, or document unless the text itself is about those things.
     * Preserve technical terminology from the source when appropriate.
     * If the input is not in English, translate concepts but keep proper nouns unchanged.
     * Do not invent information that is not supported by the input text.
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

  @doc """
  Processes a raw text chunk into a fully-formed `Api.Article` struct.

  The pipeline performs the following steps:
    1. Normalises the text and scores its relevance via an LLM call.
    2. If the relevance score is below the configured threshold, the chunk is
       dropped and `{:dropped, reason}` is returned.
    3. Generates a title and description for the normalised text.
    4. Produces embeddings for both the description and the full content.
    5. Returns the assembled article with all fields populated.

  ## Parameters

    - `chunk` - A raw text string to process.

  ## Return values

    - `{:ok, %Api.Article{}}` – article was created successfully.
    - `{:dropped, reason}` – chunk was below the minimum relevance threshold;
      `reason` is a string explaining why.
    - `{:error, reason}` – an LLM or embedding call failed.
  """
  @spec create_article(String.t()) ::
          {:ok, Api.Article.t()}
          | {:dropped, String.t()}
          | {:error, any()}
  def create_article(chunk) do
    debug_enabled = Application.get_env(:api, Api.Loader)[:debug] || false

    embedding_model =
      Application.get_env(:api, Api.Loader)[:embedding_model] || "openai/text-embedding-3-small"

    minimal_relevance_score =
      Application.get_env(:api, Api.Loader)[:minimal_relevance_score] || 0.5

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
