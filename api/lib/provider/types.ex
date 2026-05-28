defmodule Api.Provider.Metadata do
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

defmodule Api.Provider.Options do
  defstruct [
    :model,
    :temperature,
    :top_p,
    :top_k,
    :presence_penalty,
    :frequency_penalty,
    :reasoning_enabled,
    :reasoning_effort,
    :format
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
          format: map() | nil
        }
end

defmodule Api.Provider.Response do
  defstruct [
    :content,
    :reasoning,
    :metadata
  ]

  @type t :: %__MODULE__{
          content: String.t(),
          reasoning: String.t(),
          metadata: Api.Provider.Metadata.t()
        }
end

defmodule Api.Provider.Embedding do
  defstruct [
    :embedding,
    :tokens,
    :cost
  ]

  @type t :: %__MODULE__{
          embedding: list(float()),
          tokens: non_neg_integer(),
          cost: float()
        }
end
