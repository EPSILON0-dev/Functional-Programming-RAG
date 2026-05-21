defmodule Model.Provider.Response do
  defstruct [
    :content,
    :reasoning,
    :metadata
  ]

  @type t :: %__MODULE__{
          content: String.t(),
          reasoning: String.t(),
          metadata: Model.Provider.Metadata.t()
        }
end
