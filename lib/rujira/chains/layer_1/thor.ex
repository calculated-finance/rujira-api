defmodule Rujira.Chains.Layer1.Thor do
  defstruct []

  def map_denom("rune"), do: {:ok, "THOR.RUNE"}

  def map_denom(denom) do
    case String.split(denom, "-", parts: 2) do
      [chain, token] -> {:ok, String.upcase(chain) <> "-" <> String.upcase(token)}
      _ -> {:error, :unknown_denom}
    end
  end
end

defimpl Rujira.Chains.Layer1.Adapter, for: Rujira.Chains.Layer1.Thor do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub

  def balances(_a, address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Thorchain.Node.stub(&all_balances/2, req) do
      Enum.reduce(balances, {:ok, []}, fn el, acc ->
        with {:ok, acc} <- acc,
             {:ok, asset} <- Rujira.Chains.Layer1.Thor.map_denom(el.denom) do
          {:ok, [%{asset: asset, amount: el.amount} | acc]}
        end
      end)
    end
  end
end
