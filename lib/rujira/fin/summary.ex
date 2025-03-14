defmodule Rujira.Fin.Summary do
  defstruct [:id, :last, :last_usd, :high, :low, :change, :volume]

  @type t :: %__MODULE__{
          id: String.t(),
          last: Decimal.t(),
          last_usd: Decimal.t(),
          high: Decimal.t(),
          low: Decimal.t(),
          change: Decimal.t(),
          volume: non_neg_integer()
        }

  def from_id(id) do
    %__MODULE__{id: id}
  end
end
