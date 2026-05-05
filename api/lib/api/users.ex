defmodule Api.Users do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :username, :string
    field :password, :string
    field :deleted_at, :utc_datetime

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

  def get_user(attrs) do
    Api.Repo.get_by(__MODULE__, username: attrs["username"])
  end
end
