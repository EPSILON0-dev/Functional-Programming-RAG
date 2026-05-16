defmodule Api.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:username, :string)
    field(:password, :string)
    field(:deleted_at, :utc_datetime)
    has_many(:chats, Api.Chat, foreign_key: :author_id)
    has_many(:messages, Api.Message, foreign_key: :author_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(users, attrs) do
    users
    |> cast(attrs, [:username, :password, :deleted_at])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def get_by_username(username) do
    with user <- Api.Repo.get_by(__MODULE__, username: username),
         false <- is_nil(user),
         true <- is_nil(user.deleted_at) do
      {:ok, user}
    else
      _ -> {:error, "User not found"}
    end
  end

  def get_by_id(id) do
    with user <- Api.Repo.get_by(__MODULE__, id: id),
         false <- is_nil(user),
         true <- is_nil(user.deleted_at) do
      {:ok, user}
    else
      _ -> {:error, "User not found"}
    end
  end
end
