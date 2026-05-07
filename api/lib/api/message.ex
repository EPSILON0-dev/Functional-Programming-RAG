defmodule Api.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:deleted_at, :utc_datetime)
    field(:content, :string)
    field(:role, :string)
    field(:provider_metadata, :map)
    field(:usage_metadata, :map)
    belongs_to(:chat, Api.Chat, foreign_key: :chat_id, type: :binary_id)
    belongs_to(:author, Api.User, foreign_key: :author_id, type: :binary_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :deleted_at,
      :content,
      :role,
      :chat_id,
      :author_id,
      :provider_metadata,
      :usage_metadata
    ])
    |> validate_required([:content, :role, :chat_id, :author_id])
    |> assoc_constraint(:author)
    |> assoc_constraint(:chat)
  end

  def new_message(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  # TODO offset limit
  def get_chat_messages(chat_id, limit \\ 20, offset \\ 0) do
    Api.Repo.all_by(__MODULE__, chat_id: chat_id)
  end
end
