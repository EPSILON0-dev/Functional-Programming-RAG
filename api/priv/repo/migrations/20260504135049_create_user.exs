defmodule Api.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :username, :string, null: false
      add :password, :text, null: false
      add :deleted_at, :utc_datetime
      add :selected_key_id, :binary_id

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:username])
  end

end
