defmodule Mix.Tasks.Rag.Load do
  use Mix.Task

  @shortdoc "Loads RAG documents into the database"

  def run(args) do
    Mix.Task.run("app.start")

    # Check for the arguments
    if length(args) != 1 do
      Mix.shell().error(
        "Please provide the path to the document to load, e.g. mix rag.load path/to/document.pdf"
      )

      System.halt(1)
    end

    # Check if there's an environment variable for the OPENROUTER_API_KEY
    if System.get_env("OPENROUTER_API_KEY") do
      Mix.shell().info("Found OPENROUTER_API_KEY in environment variables")
    else
      Mix.shell().error(
        "OPENROUTER_API_KEY is not set, please set it to be able to load documents"
      )

      System.halt(1)
    end

    # Check if pdftotext is available
    if args |> List.first() |> String.ends_with?(".pdf") do
      with {output, 0} <- System.cmd("pdftotext", ["-v"], stderr_to_stdout: true) do
        Mix.shell().info(
          "Found pdftotext version: #{output |> String.split("\n") |> List.first()}"
        )
      else
        _ ->
          Mix.shell().error(
            "Failed to run pdftotext, please install it to be able to load PDF documents"
          )

          System.halt(1)
      end
    end

    # Load the document
    case Api.Loader.load_document(List.first(args, "")) do
      {:ok, _} ->
        Mix.shell().info("Document loaded successfully")

      {:error, reason} ->
        Mix.shell().error("Failed to load document: #{reason}")
        System.halt(1)
    end
  end
end
