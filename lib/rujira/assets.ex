defmodule Rujira.Assets do
  use Memoize
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.Query.Stub, as: Q
  alias __MODULE__.Asset

  defmemo assets() do
    with {:ok, %{pools: pools}} <- Thorchain.Node.stub(&Q.pools/2, %QueryPoolsRequest{}) do
      Enum.map(pools, &from_string(&1.asset))
    end
  end

  def erc20(chain) do
    chain = chain |> Kernel.to_string() |> String.upcase()

    Enum.filter(
      assets(),
      &(&1.chain == chain && String.starts_with?(&1.symbol, "#{&1.ticker}-0X"))
    )
  end

  @doc """
  Convert string notation to an Assets.Asset
  """
  def from_string(id) do
    %Asset{
      id: id,
      type: type(id),
      chain: chain(id),
      symbol: symbol(id),
      ticker: ticker(id)
    }
  end

  def to_string(%Asset{id: id}), do: id

  @moduledoc """
  Interfaces for interacting with THORChain Asset values
  """
  def chain("x/" <> _), do: "THOR"

  def chain(str) do
    [c | _] = String.split(str, [".", "-"])
    c
  end

  def symbol("x/" <> id), do: String.upcase(id)

  def symbol(str) do
    [_, v] = String.split(str, [".", "-"], parts: 2)
    v
  end

  def ticker("x/" <> id), do: String.upcase(id)

  def ticker(str) do
    [_, v] = String.split(str, [".", "-"], parts: 2)
    [sym | _] = String.split(v, "-")
    sym
  end

  def decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "AVAX"}), do: 18
  def decimals(%{type: :layer_1, chain: "BASE", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "BASE"}), do: 18
  def decimals(%{type: :layer_1, chain: "BCH"}), do: 8
  def decimals(%{type: :layer_1, chain: "BTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "BSC", ticker: "USDC"}), do: 8
  def decimals(%{type: :layer_1, chain: "BSC"}), do: 18
  def decimals(%{type: :layer_1, chain: "DOGE"}), do: 8
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "ETH"}), do: 18
  def decimals(%{type: :layer_1, chain: "GAIA"}), do: 6
  def decimals(%{type: :layer_1, chain: "KUJI"}), do: 6
  def decimals(%{type: :layer_1, chain: "LTC"}), do: 8
  def decimals(_), do: 8

  def type(str) do
    cond do
      String.match?(str, ~r/^[A-Z]+\./) -> :layer_1
      String.match?(str, ~r/^[A-Z]+-/) -> :secured
      true -> :native
    end
  end

  def to_native(%{id: "THOR.RUNE"}), do: {:ok, "rune"}
  def to_native(%{id: "THOR." <> _ = id}), do: {:ok, String.downcase(id)}
  def to_native(%{id: "x/" <> _ = denom}), do: {:ok, denom}

  def to_native(%{type: "SECURED", chain: chain, symbol: symbol}) do
    {:ok, String.downcase(chain) <> "-" <> String.downcase(symbol)}
  end

  def to_native(_), do: {:ok, nil}

  def to_layer1(%Asset{chain: "THOR"}), do: nil

  def to_layer1(%Asset{id: id} = a) do
    %{a | type: :layer_1, id: String.replace(id, ~r/[\.\-]/, ".")}
  end

  def to_secured(%Asset{chain: "THOR"}), do: nil

  def to_secured(%Asset{id: id} = a) do
    %{a | type: :secured, id: String.replace(id, ~r/[\.\-]/, "-")}
  end

  @doc """
  Converts a denom string to a THORChain asset - native token or

  This will only convert
  """
  def from_denom("rune") do
    {:ok, %Asset{id: "THOR.RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}}
  end

  def from_denom("thor." <> symbol) do
    symbol = String.upcase(symbol)

    {:ok,
     %Asset{id: "THOR.#{symbol}", type: :native, chain: "THOR", symbol: symbol, ticker: symbol}}
  end

  def from_denom("x/" <> id = denom) do
    {:ok,
     %Asset{
       id: denom,
       type: :native,
       chain: "THOR",
       symbol: String.upcase(id),
       ticker: String.upcase(id)
     }}
  end

  def from_denom(denom) do
    case denom |> String.upcase() |> String.split("-", parts: 2) do
      [chain, symbol] ->
        [ticker | _] = String.split(symbol, "-")

        {:ok,
         %Asset{
           id: "#{chain}-#{symbol}",
           type: :secured,
           chain: chain,
           symbol: symbol,
           ticker: ticker
         }}

      _ ->
        {:error, "Invalid Denom #{denom}"}
    end
  end
end
