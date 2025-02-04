defmodule Rujira.Chains.Thor do
  defstruct []
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Thor do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Rujira.Assets

  def balances(_a, address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Thorchain.Node.stub(&all_balances/2, req) do
      Enum.reduce(balances, {:ok, []}, fn el, acc ->
        with {:ok, acc} <- acc,
             {:ok, asset} <- Assets.from_denom(el.denom) do
          {:ok, [%{asset: asset, amount: el.amount} | acc]}
        end
      end)
    end
  end
end
