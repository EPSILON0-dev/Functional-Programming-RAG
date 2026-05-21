defmodule Api.Workers.GenerateTitleJobArgs do
  @derive Jason.Encoder
  defstruct [
    :chat_id,
    :user_id,
    :api_key
  ]

  @type t :: %__MODULE__{
          chat_id: String.t(),
          user_id: String.t(),
          api_key: String.t()
        }
end

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
