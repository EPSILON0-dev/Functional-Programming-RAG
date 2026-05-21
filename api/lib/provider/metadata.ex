defmodule Model.Provider.Metadata do
  @derive Jason.Encoder

  defstruct [
    :id,
    :input_tokens,
    :output_tokens,
    :total_tokens,
    :input_cost,
    :output_cost,
    :total_cost,
    :provider,
    :model,
    :provider_model
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          input_tokens: non_neg_integer(),
          output_tokens: non_neg_integer(),
          total_tokens: non_neg_integer(),
          input_cost: float(),
          output_cost: float(),
          total_cost: float(),
          provider: String.t(),
          model: String.t(),
          provider_model: String.t()
        }
end
