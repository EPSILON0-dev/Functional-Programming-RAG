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

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :deleted_at, :author_id])
    |> validate_required([:name, :author_id])
    |> assoc_constraint(:author)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def rename_by_id(chat_id, user_id, new_name) do
    with chat <- Api.Repo.get_by(__MODULE__, id: chat_id, author_id: user_id),
         false <- is_nil(chat),
         true <- is_nil(chat.deleted_at) do
      chat
      |> changeset(%{name: new_name})
      |> Api.Repo.update()
    else
      _ -> {:error, "Chat not found"}
    end
  end

  def delete_by_id(chat_id, user_id) do
    with chat <- Api.Repo.get_by(__MODULE__, id: chat_id, author_id: user_id),
         false <- is_nil(chat),
         true <- is_nil(chat.deleted_at) do
      chat
      |> changeset(%{deleted_at: DateTime.truncate(DateTime.utc_now(), :second)})
      |> Api.Repo.update()
    else
      _ -> {:error, "Chat not found"}
    end
  end

  def get_by_id(chat_id, user_id) do
    with chat <- Api.Repo.get_by(__MODULE__, id: chat_id, author_id: user_id),
         false <- is_nil(chat),
         true <- is_nil(chat.deleted_at) do
      {:ok, chat}
    else
      _ -> {:error, "Chat not found"}
    end
  end

  def get_by_user_id(user_id) do
    Api.Repo.all_by(__MODULE__, author_id: user_id)
    |> Enum.filter(fn chat -> is_nil(chat.deleted_at) end)
  end

  def to_public(%__MODULE__{} = chat) do
    %Api.ChatPublic{
      id: chat.id,
      name: chat.name,
      author_id: chat.author_id,
      timestamp: chat.inserted_at
    }
  end
end
