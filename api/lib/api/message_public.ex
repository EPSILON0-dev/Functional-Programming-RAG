defmodule Api.MessagePublic do

  @derive Jason.Encoder
  defstruct [
    :id,
    :content,
    :role,
    :chat_id,
    :author_id,
    :metadata,
    :timestamp,
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          content: String.t(),
          role: String.t(),
          chat_id: String.t(),
          author_id: String.t(),
          metadata: map(),
          timestamp: DateTime.t(),
        }
end
