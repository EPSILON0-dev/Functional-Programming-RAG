defmodule Api.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :username, :string
    field :password, :string
    field :deleted_at, :utc_datetime
    has_many :chats, Api.Chat, foreign_key: :author_id
    has_many :messages, Api.Message, foreign_key: :author_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(users, attrs) do
    users
    |> cast(attrs, [:username, :password, :deleted_at])
    |> validate_required([:username, :password])
    |> unique_constraint(:username)
  end

  def create_user(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def get_user_by_username(username) do
    Api.Repo.get_by(__MODULE__, username: username)
  end

  def get_user_by_id(id) do
    Api.Repo.get_by(__MODULE__, id: id)
  end
end
