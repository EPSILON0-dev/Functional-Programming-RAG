defmodule Api.Repo.Migrations.CreateApikeys do
  use Ecto.Migration

  def change do
    create table(:apikeys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :encrypted_key, :binary
      add :owner_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end
  end
end
