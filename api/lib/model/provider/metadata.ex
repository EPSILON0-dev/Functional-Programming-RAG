defmodule Model.Provider.Metadata do
  @derive Jason.Encoder

  defstruct [
    :id,
    :input_tokens,
    :cached_tokens,
    :reasoning_tokens,
    :output_tokens,
    :total_tokens,
    :input_cost,
    :output_cost,
    :total_cost,
    :cost_currency,
    :provider,
    :model,
    :provider_model,
    :temperature,
    :top_p,
    :top_k,
    :presence_penalty,
    :frequency_penalty,
    :reasoning_enabled,
    :reasoning_effort
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          input_tokens: non_neg_integer(),
          cached_tokens: non_neg_integer(),
          reasoning_tokens: non_neg_integer(),
          output_tokens: non_neg_integer(),
          total_tokens: non_neg_integer(),
          input_cost: float(),
          output_cost: float(),
          total_cost: float(),
          cost_currency: String.t(),
          provider: String.t(),
          model: String.t(),
          provider_model: String.t(),
          temperature: float(),
          top_p: float(),
          top_k: non_neg_integer(),
          presence_penalty: float(),
          frequency_penalty: float(),
          reasoning_enabled: boolean(),
          reasoning_effort: String.t()
        }
end
