defmodule Model.Provider.Options do
  defstruct [
    :model,
    :temperature,
    :top_p,
    :top_k,
    :presence_penalty,
    :frequency_penalty,
    :reasoning_enabled,
    :reasoning_effort,
    :responseFormat
  ]

  @type t :: %__MODULE__{
          model: String.t(),
          temperature: float() | nil,
          top_p: float() | nil,
          top_k: non_neg_integer() | nil,
          presence_penalty: float() | nil,
          frequency_penalty: float() | nil,
          reasoning_enabled: boolean() | nil,
          reasoning_effort: String.t() | nil,
          responseFormat: map() | nil
        }
end
