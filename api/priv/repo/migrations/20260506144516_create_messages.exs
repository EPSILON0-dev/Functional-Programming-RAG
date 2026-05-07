defmodule Api.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :deleted_at, :utc_datetime
      add :content, :text
      add :role, :string
      add :provider_metadata, :map
      add :usage_metadata, :map
      add :chat_id, references(:chats, on_delete: :nothing, type: :binary_id)
      add :author_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:chat_id, :inserted_at])
  end
end
