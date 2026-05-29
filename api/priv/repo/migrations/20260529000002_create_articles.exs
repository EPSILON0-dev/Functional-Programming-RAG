defmodule Api.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text, null: false
      add :content, :text, null: false
      add :description_embedding, :vector, size: 1536
      add :content_embedding, :vector, size: 1536
      add :generation_cost, :float, null: false
      add :embedding_model, :string, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
