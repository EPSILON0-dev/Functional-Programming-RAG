defmodule Api.MessagePublic do
  @derive Jason.Encoder
  defstruct [
    :id,
    :content,
    :role,
    :chat_id,
    :author_id,
    :metadata,
    :timestamp
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          content: String.t(),
          role: String.t(),
          chat_id: String.t(),
          author_id: String.t(),
          metadata: map(),
          timestamp: DateTime.t()
        }
end

defmodule Api.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages" do
    field(:deleted_at, :utc_datetime)
    field(:content, :string)
    field(:role, :string)
    field(:metadata, :map)
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
      :metadata
    ])
    |> validate_required([:role, :chat_id])
    |> assoc_constraint(:author)
    |> assoc_constraint(:chat)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Api.Repo.insert()
  end

  def delete_by_chat_id(chat_id, user_id) do
    with messages <- Api.Repo.all_by(__MODULE__, chat_id: chat_id, author_id: user_id),
         false <- is_nil(messages),
         true <- Enum.all?(messages, fn message -> is_nil(message.deleted_at) end) do
      Enum.each(messages, fn message ->
        message
        |> change(deleted_at: DateTime.truncate(DateTime.utc_now(), :second))
        |> Api.Repo.update()
      end)
    else
      _ -> {:error, "Chat not found"}
    end
  end

  def update_by_id(id, attrs) do
    case Api.Repo.get(__MODULE__, id) do
      nil ->
        {:error, "Message not found"}

      %{deleted_at: nil} = message ->
        message
        |> changeset(attrs)
        |> Api.Repo.update()
    end
  end

  def get_by_chat_id(chat_id, user_id) do
    with {:ok, _chat} <- Api.Chat.get_by_id(chat_id, user_id) do
      {:ok,
       Api.Repo.all_by(__MODULE__, chat_id: chat_id)
       |> Enum.filter(fn message -> is_nil(message.deleted_at) end)}
    else
      _ -> {:error, "Chat not found or access denied"}
    end
  end

  def delete_by_id(message_id, chat_id, user_id) do
    with {:ok, _chat} <- Api.Chat.get_by_id(chat_id, user_id),
         message <- Api.Repo.get(__MODULE__, message_id),
         false <- is_nil(message),
         true <- is_nil(message.deleted_at),
         true <- message.chat_id == chat_id do
      message
      |> changeset(%{deleted_at: DateTime.truncate(DateTime.utc_now(), :second)})
      |> Api.Repo.update()
    else
      _ -> {:error, "Message not found or access denied"}
    end
  end

  def get_last_message_by_chat_id(chat_id) do
    Api.Repo.all_by(__MODULE__, chat_id: chat_id)
    |> Enum.filter(fn message -> is_nil(message.deleted_at) end)
    |> Enum.sort_by(& &1.inserted_at, :asc)
    |> List.last()
  end

  def to_public(%__MODULE__{} = message) do
    %Api.MessagePublic{
      id: message.id,
      content: message.content,
      role: message.role,
      chat_id: message.chat_id,
      author_id: message.author_id,
      metadata: message.metadata,
      timestamp: message.inserted_at
    }
  end
end
