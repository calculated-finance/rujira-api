defmodule Rujira.Assets do
  use Memoize
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.Query.Stub, as: Q

  defmemo assets() do
    with {:ok, %{pools: pools}} <- Thorchain.Node.stub(&Q.pools/2, %QueryPoolsRequest{}) do
      Enum.map(
        pools,
        &{&1.asset,
         if &1.decimals == 0 do
           8
         else
           &1.decimals
         end}
      )
    end
  end

  def erc20(chain) do
    chain_name = chain |> Atom.to_string() |> String.upcase()

    assets()
    |> Enum.reduce([], fn
      {^chain_name <> _ = asset, _decimal}, acc ->
        case String.split(asset, "-0X") do
          [_, address] -> [{asset, "0x" <> address} | acc]
          _ -> acc
        end

      _, acc ->
        acc
    end)
  end

  @moduledoc """
  Interfaces for interacting with THORChain Asset values
  """

  def chain(str) do
    # TODO: suport more delimiters
    [c | _] = String.split(str, [".", "-"])
    c
  end

  def symbol("GAIA.RKUJI"), do: "rKUJI"
  def symbol("KUJI.RKUJI"), do: "rKUJI"

  def symbol(str) do
    # TODO: suport more delimiters
    [_, v | _] = String.split(str, [".", "-"])
    [sym | _] = String.split(v, "-")
    sym
  end

  def decimals("AVAX.USDC" <> _), do: 6
  def decimals("AVAX." <> _), do: 18
  def decimals("BASE.USDC" <> _), do: 6
  def decimals("BASE." <> _), do: 18
  def decimals("BCH." <> _), do: 8
  def decimals("BTC." <> _), do: 8
  def decimals("BSC.USDC" <> _), do: 8
  def decimals("BSC." <> _), do: 18
  def decimals("DOGE." <> _), do: 8
  def decimals("ETH.USDC" <> _), do: 6
  def decimals("ETH." <> _), do: 18
  def decimals("GAIA." <> _), do: 6
  def decimals("KUJI." <> _), do: 6
  def decimals("LTC." <> _), do: 8
  def decimals(_), do: 8

  # TODO: Decimals differ between Layer 1 balances and THORChain secured asset balance
  # https://dev.thorchain.org/concepts/querying-thorchain.html#decimals-and-base-units
  # defmemo decimals(asset) do
  #   req = %QueryPoolRequest{asset: asset}

  #   case Thorchain.Node.stub(&Q.pool/2, req) do
  #     {:ok, %{decimals: 0}} -> 8
  #     {:ok, %{decimals: d}} -> d
  #     _ -> 8
  #   end
  # end

  def type(str) do
    cond do
      String.match?(str, ~r/^[A-Z]+\./) -> :layer_1
      String.match?(str, ~r/^[A-Z]+-/) -> :secured
      true -> :native
    end
  end

  def to_layer_1(str) do
    String.replace(str, ~r/[\-\.]/, ".", global: false)
  end

  def to_secured(str) do
    String.replace(str, ".", "-", global: true)
  end

  @doc """
  Converts an Asset string to a Cosmos SDK x/bank denom string

  For Layer 1 assets, this will return a value if the Layer 1 chain is Cosmos SDK
  For Secured assets, this will return the THORChain x/bank denom string for the secured asset
  """
  def to_native("THOR." <> denom), do: {:ok, String.downcase(denom)}

  def to_native("KUJI." <> _ = denom), do: Rujira.Chains.Kuji.to_denom(denom)
  def to_native("GAIA." <> _ = denom), do: Rujira.Chains.Gaia.to_denom(denom)

  def to_native(asset) do
    case String.split(asset, "-", parts: 2) do
      [chain, token] -> {:ok, String.downcase(chain) <> "-" <> String.downcase(token)}
      _ -> {:ok, nil}
    end
  end

  @doc """
  Converts a denom string to a THORChain Layer 1 representation of the asset.

  This will only convert
  """
  def from_native("rune"), do: {:ok, "THOR.RUNE"}

  def from_native(asset) do
    case String.split(asset, "-", parts: 2) do
      [chain, token] -> {:ok, String.upcase(chain) <> "." <> String.upcase(token)}
      _ -> {:error, :invalid_denom}
    end
  end
end
