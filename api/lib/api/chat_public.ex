defmodule Api.ChatPublic do

  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :author_id,
    :timestamp
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          author_id: String.t(),
          timestamp: DateTime.t()
        }
end
