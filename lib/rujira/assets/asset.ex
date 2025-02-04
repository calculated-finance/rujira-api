defmodule Rujira.Assets.Asset do
  defstruct [:id, :type, :chain, :symbol, :ticker]

  @type t :: %__MODULE__{
          id: String.t(),
          type: :native | :secured | :layer_1,
          chain: String.t(),
          symbol: String.t(),
          ticker: String.t()
        }
end
