defmodule Api.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chats" do
    field(:name, :string)
    field(:deleted_at, :utc_datetime)
    belongs_to(:author, Api.User, foreign_key: :author_id, type: :binary_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :deleted_at, :author_id])
    |> validate_required([:name, :author_id])
    |> assoc_constraint(:author)
  end

  def new_chat(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def get_chat_by_id(user_id, id) do
    Api.Repo.get_by(__MODULE__, id: id, author_id: user_id)
  end

  # TODO Add pagination?
  def get_user_chats(user_id) do
    Api.Repo.all_by(__MODULE__, author_id: user_id)
    |> Enum.map(&%{id: &1.id, name: &1.name})
  end
end
