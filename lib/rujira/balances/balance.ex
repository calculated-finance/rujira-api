defmodule Rujira.Balances.Balance do
  @moduledoc false
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  
  defstruct [:asset, :amount]

  @type t :: %__MODULE__{
          asset: Asset.t(),
          amount: non_neg_integer()
        }

  def parse(%{"denom" => denom, "amount" => amount}) do
    with {:ok, asset} <- Assets.from_denom(denom) do
      {:ok, %__MODULE__{asset: asset, amount: amount}}
    end
  end

  def parse(nil), do: {:ok, nil}
end
