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

defmodule Api.Workers.RunPipelineJobArgs do
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

defmodule Api.Workers.PipelineState do
  @moduledoc "Typed state threaded through all stages of RunPipelineJob."

  @enforce_keys [:gen_id, :user_id, :chat_id, :history, :question, :api_key, :is_first_message]
  defstruct [
    # Job identity
    :gen_id,
    :user_id,
    :chat_id,
    # Input
    :history,
    :question,
    :api_key,
    :is_first_message,
    # Accumulated pipeline cost
    cost: 0.0,
    # Stage outputs (populated as the pipeline progresses)
    topic: nil,
    uninformed_response: nil,
    articles: [],
    top_articles: [],
    candidates: []
  ]

  @type t :: %__MODULE__{
          gen_id: String.t(),
          user_id: String.t(),
          chat_id: String.t(),
          history: list(map()),
          question: String.t(),
          api_key: String.t(),
          is_first_message: boolean(),
          cost: float(),
          topic: map() | nil,
          uninformed_response: String.t() | nil,
          articles: list(map()),
          top_articles: list(map()),
          candidates: list(map())
        }
end
