defmodule Api.Workers.GenerateResponseJobArgs do

  @derive Jason.Encoder
  defstruct [
    :message,
    :api_key,
    :is_first_message
  ]

  @type t :: %__MODULE__{
          message: Api.MessagePublic.t(),
          api_key: String.t(),
          is_first_message: boolean()
        }
end
