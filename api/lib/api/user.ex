defmodule Api.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:username, :string)
    field(:password, :string)
    field(:deleted_at, :utc_datetime)
    field(:selected_key_id, :binary_id)
    has_many(:chats, Api.Chat, foreign_key: :author_id)
    has_many(:messages, Api.Message, foreign_key: :author_id)
    has_many(:api_keys, Api.APIKey, foreign_key: :owner_id)

    timestamps(type: :utc_datetime)
  end

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

  def set_selected_key(user_id, key_id) do
    with {:ok, user} <- get_by_id(user_id) do
      user
      |> change(%{selected_key_id: key_id})
      |> Api.Repo.update()
    end
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

  def rename(user_id, new_username) do
    with {:ok, user} <- get_by_id(user_id) do
      user
      |> changeset(%{username: new_username})
      |> Api.Repo.update()
    end
  end

  def change_password(user_id, new_password_hash) do
    with {:ok, user} <- get_by_id(user_id) do
      user
      |> change(%{password: new_password_hash})
      |> Api.Repo.update()
    end
  end

  def delete(user_id) do
    with {:ok, user} <- get_by_id(user_id) do
      user
      |> change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      |> Api.Repo.update()
    end
  end
end
