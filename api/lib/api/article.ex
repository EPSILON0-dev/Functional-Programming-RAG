defmodule Api.ArticlePublic do
  @derive Jason.Encoder
  defstruct [
    :id,
    :title,
    :description,
    :content,
    :generation_cost,
    :embedding_model,
    :inserted_at,
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          description: String.t(),
          content: String.t(),
          generation_cost: float(),
          embedding_model: String.t(),
          inserted_at: DateTime.t()
        }
end

defmodule Api.Article do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "articles" do
    field(:title, :string)
    field(:description, :string)
    field(:content, :string)
    field(:description_embedding, Pgvector.Ecto.Vector)
    field(:content_embedding, Pgvector.Ecto.Vector)
    field(:generation_cost, :float)
    field(:embedding_model, :string)

    timestamps(type: :utc_datetime)
  end

  @type t :: %__MODULE__{
          id: String.t() | nil,
          title: String.t(),
          description: String.t(),
          content: String.t(),
          description_embedding: Pgvector.t() | nil,
          content_embedding: Pgvector.t() | nil,
          generation_cost: float(),
          embedding_model: String.t()
        }

  def changeset(article, attrs) do
    article
    |> cast(attrs, [
      :title,
      :description,
      :content,
      :description_embedding,
      :content_embedding,
      :generation_cost,
      :embedding_model
    ])
    |> validate_required([:title, :description, :content, :generation_cost, :embedding_model])
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def save(%__MODULE__{} = article) do
    %__MODULE__{}
    |> changeset(Map.from_struct(article))
    |> Api.Repo.insert()
  end

  def to_public(%__MODULE__{} = article) do
    %Api.ArticlePublic{
      id: article.id,
      title: article.title,
      description: article.description,
      content: article.content,
      generation_cost: article.generation_cost,
      embedding_model: article.embedding_model,
      inserted_at: article.inserted_at,
    }
  end

  def get_by_id(id) do
    case Api.Repo.get(__MODULE__, id) do
      nil -> {:error, "Article not found"}
      article -> {:ok, article}
    end
  end

  def get_all() do
    Api.Repo.all(__MODULE__)
  end

  def get_paginated(offset, limit) do
    __MODULE__
    |> order_by([a], asc: a.inserted_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Api.Repo.all()
  end

  def count() do
    Api.Repo.aggregate(__MODULE__, :count, :id)
  end

  def search(query, limit) do
    pattern = "%#{String.replace(query, ["%", "_", "\\"], fn c -> "\\" <> c end)}%"

    __MODULE__
    |> where(
      [a],
      ilike(a.title, ^pattern) or ilike(a.description, ^pattern)
    )
    |> order_by([a], [
      asc:
        fragment(
          "CASE WHEN ? ILIKE ? THEN 0 ELSE 1 END",
          a.title,
          ^pattern
        ),
      asc: a.inserted_at
    ])
    |> limit(^limit)
    |> Api.Repo.all()
  end
end
