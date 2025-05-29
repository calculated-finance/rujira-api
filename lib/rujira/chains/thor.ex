defmodule Rujira.Chains.Thor do
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Rujira.Assets
  use Memoize

  defmemo balance_of(address, denom) do
    req = %QueryBalanceRequest{address: address, denom: denom}

    with {:ok, %QueryBalanceResponse{balance: %{amount: balance}}} <-
           Thorchain.Node.stub(&balance/2, req) do
      with {:ok, asset} <- Assets.from_denom(denom) do
        {:ok, %{asset: asset, amount: balance}}
      end
    end
  end

  def balances(address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Thorchain.Node.stub(&all_balances/2, req) do
      balances
      # Remove LSD, Lending shares, LP shares etc from regular balances,
      # surface them in the account/pooled account/staked lists
      |> Enum.filter(&is_balance/1)
      |> Enum.reduce({:ok, []}, fn el, acc ->
        with {:ok, acc} <- acc,
             {:ok, asset} <- Assets.from_denom(el.denom) do
          {:ok, [%{asset: asset, amount: el.amount} | acc]}
        end
      end)
    end
  end

  defp is_balance(%{denom: "x/staking" <> _}), do: false
  defp is_balance(%{denom: "x/bow" <> _}), do: false
  defp is_balance(_), do: true
end
