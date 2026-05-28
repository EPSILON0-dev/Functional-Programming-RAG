defmodule Api.ArticlePublic do
  @derive Jason.Encoder
  defstruct [
    :id,
    :title,
    :description,
    :content,
    :description_embedding,
    :content_embedding,
    :generation_cost,
    :embedding_model
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          title: String.t(),
          description: String.t(),
          content: String.t(),
          description_embedding: list(float),
          content_embedding: list(float),
          generation_cost: float,
          embedding_model: String.t()
        }
end
