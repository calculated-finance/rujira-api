defmodule Rujira.Chains.Thor do
  @moduledoc """
  Implements the Thorchain adapter for Cosmos compatibility.
  """
  # Aliases
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Rujira.Assets

  # Imports
  import Cosmos.Bank.V1beta1.Query.Stub

  # Uses
  use Memoize

  defmemo balance_of(address, denom) do
    req = %QueryBalanceRequest{address: address, denom: denom}

    with {:ok, %QueryBalanceResponse{balance: %{amount: balance}}} <-
           Thornode.query(&balance/2, req) do
      with {:ok, asset} <- Assets.from_denom(denom) do
        {:ok, %{asset: asset, amount: balance}}
      end
    end
  end

  def balances(address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Thornode.query(&all_balances/2, req) do
      balances
      # Remove LSD, Lending shares, LP shares etc from regular balances,
      # surface them in the account/pooled account/staked lists
      |> Enum.filter(&balance?/1)
      |> Enum.reduce({:ok, []}, fn el, acc ->
        with {:ok, acc} <- acc,
             {:ok, asset} <- Assets.from_denom(el.denom) do
          {:ok, [%{asset: asset, amount: el.amount} | acc]}
        end
      end)
    end
  end

  defp balance?(%{denom: "x/staking" <> _}), do: false
  defp balance?(%{denom: "x/bow" <> _}), do: false
  defp balance?(%{denom: "x/nami-index" <> _}), do: false
  defp balance?(_), do: true
end
