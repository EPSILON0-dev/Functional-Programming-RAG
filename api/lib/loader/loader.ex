defmodule Api.Loader do
  @spec load_pdf(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp load_pdf(path) do
    with {output, 0} <- System.cmd("pdftotext", ["-layout", path, "-"], stderr_to_stdout: true) do
      {:ok, output}
    else
      {error_output, _} ->
        {:error, "Failed to load PDF: #{error_output}"}
    end
  end

  @spec load_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp load_file(path) do
    if String.ends_with?(path, ".pdf") do
      load_pdf(path)
    else
      File.read(path)
    end
  end

  @spec create_chunks(String.t(), non_neg_integer(), non_neg_integer()) :: [String.t()]
  defp create_chunks(
         text,
         chunk_size \\ Application.get_env(:api, Api.Loader)[:chunk_size] || 4000,
         overlap_size \\ Application.get_env(:api, Api.Loader)[:overlap_size] || 750
       ) do
    text
    |> String.graphemes()
    |> Enum.chunk_every(chunk_size, chunk_size - overlap_size, [])
    |> Enum.map(&Enum.join/1)
  end

  defp log_article_creation({:ok, {:ok, article}}) do
    IO.puts(
      "Generated Article: (#{Float.round(article.generation_cost * 100.0, 3) || 0.0} cents) #{article.title}"
    )

    {:ok, article}
  end

  defp log_article_creation({:ok, {:dropped, reason}}) do
    IO.inspect(reason, label: "Dropped Article")
    {:dropped, reason}
  end

  defp log_article_creation({_, reason}) do
    IO.inspect(reason, label: "Failed Article Creation")
    {:error, reason}
  end

  @spec load_document(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def load_document(path) do
    concurrency = Application.get_env(:api, Api.Loader)[:processing_concurrency] || 8
    timeout = Application.get_env(:api, Api.Loader)[:job_timeout_seconds] || 120
    IO.puts("Loading document from path \"#{path}\" with concurrency: #{concurrency}")

    with {:ok, text} <- load_file(path) do
      chunks = create_chunks(text)

      IO.puts("Created #{length(chunks)} chunks from document")

      articles =
        chunks
        |> Task.async_stream(&Api.Pipeline.CreateArticle.create_article/1,
          max_concurrency: concurrency,
          timeout: timeout * 1000
        )
        |> Stream.map(&log_article_creation/1)
        |> Stream.filter(fn
          {:ok, _article} -> true
          _ -> false
        end)
        |> Enum.map(fn {_result, article} -> article end)
        |> Enum.to_list()

      {:ok, chunks}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
