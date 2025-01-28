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

  def symbol(str) do
    # TODO: suport more delimiters
    [_, v | _] = String.split(str, [".", "-"])
    [sym | _] = String.split(v, "-")
    sym
  end

  def decimals("AVAX.USDC" <> _), do: 6
  def decimals("AVAX" <> _), do: 18
  def decimals("BASE.USDC" <> _), do: 6
  def decimals("BASE" <> _), do: 18
  def decimals("BCH" <> _), do: 8
  def decimals("BTC" <> _), do: 8
  def decimals("BSC.USDC" <> _), do: 8
  def decimals("BSC" <> _), do: 18
  def decimals("DOGE" <> _), do: 8
  def decimals("ETH.USDC" <> _), do: 6
  def decimals("ETH" <> _), do: 18
  def decimals("GAIA" <> _), do: 6
  def decimals("LTC" <> _), do: 8
  def decimals("THOR" <> _), do: 6

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
    String.replace(str, "-", ".", global: false)
  end

  def to_secured(str) do
    String.replace(str, ".", "-", global: false)
  end

  @doc """
  Converts an Asset string to a Cosmos SDK x/bank denom string

  For Layer 1 assets, this will return a value if the Layer 1 chain is Cosmos SDK
  For Secured assets, this will return the THORChain x/bank denom string for the secured asset
  """
  def to_native("THOR." <> denom), do: {:ok, String.downcase(denom)}

  def to_native("GAIA.ATOM"), do: {:ok, "uatom"}

  def to_native("GAIA.KUJI"),
    do: {:ok, "ibc/4CC44260793F84006656DD868E017578F827A492978161DA31D7572BCB3F4289"}

  def to_native("GAIA.RKUJI"),
    do: {:ok, "ibc/50A69DC508ACCADE2DAC4B8B09AA6D9C9062FCBFA72BB4C6334367DECD972B06"}

  def to_native("GAIA.FUZN"),
    do: {:ok, "ibc/6BBBB4B63C51648E9B8567F34505A9D5D8BAAC4C31D768971998BE8C18431C26"}

  def to_native("GAIA.WINK"),
    do: {:ok, "ibc/4363FD2EF60A7090E405B79A6C4337C5E9447062972028F5A99FB041B9571942"}

  def to_native("GAIA.NSTK"),
    do: {:ok, "ibc/0B99C4EFF1BD05E56DEDEE1D88286DB79680C893724E0E7573BC369D79B5DDF3"}

  def to_native("GAIA.LVN"),
    do: {:ok, "ibc/6C95083ADD352D5D47FB4BA427015796E5FEF17A829463AD05ECD392EB38D889"}

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
