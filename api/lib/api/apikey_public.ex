defmodule Api.APIKeyPublic do
  @derive Jason.Encoder
  defstruct [
    :id,
    :key,
    :name,
    :owner_id,
    :timestamp
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          key: String.t(),
          name: String.t(),
          owner_id: String.t(),
          timestamp: DateTime.t()
        }
end
