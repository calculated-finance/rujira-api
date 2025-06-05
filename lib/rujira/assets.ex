defmodule Rujira.Assets do
  use Memoize
  alias Rujira.Bow
  alias Rujira.Deployments
  alias Rujira.Assets.Metadata
  alias Thorchain.Types.QueryPoolsRequest
  alias Thorchain.Types.Query.Stub, as: Q
  alias __MODULE__.Asset

  @delimiters [".", "-", "/", "~"]
  # https://github.com/cosmos/cosmos-sdk/blob/main/types/coin.go#L871
  @coin_regex ~r/^(\d+(?:\.\d+)?|\.\d+)\s*([a-zA-Z][a-zA-Z0-9\/:._-]{2,127})$/

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

  def from_id(id) do
    {:ok, from_string(id)}
  end

  def to_string(%Asset{id: id}), do: id

  @moduledoc """
  Interfaces for interacting with THORChain Asset values
  """
  def chain("x/" <> _), do: "THOR"

  def chain(str) do
    [c | _] = String.split(str, @delimiters)
    c
  end

  def symbol("x/" <> id), do: String.upcase(id)

  def symbol(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    v
  end

  def ticker("x/" <> id), do: String.upcase(id)

  def ticker(str) do
    [_, v] = String.split(str, @delimiters, parts: 2)
    [sym | _] = String.split(v, "-")
    sym
  end

  def decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "AVAX", ticker: "USDT"}), do: 6
  def decimals(%{type: :layer_1, chain: "AVAX"}), do: 18
  def decimals(%{type: :layer_1, chain: "BASE", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "BASE"}), do: 18
  def decimals(%{type: :layer_1, chain: "BCH"}), do: 8
  def decimals(%{type: :layer_1, chain: "BTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "BSC"}), do: 18
  def decimals(%{type: :layer_1, chain: "DOGE"}), do: 8
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "USDC"}), do: 6
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "USDT"}), do: 6
  def decimals(%{type: :layer_1, chain: "ETH", ticker: "WBTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "ETH"}), do: 18
  def decimals(%{type: :layer_1, chain: "GAIA"}), do: 6
  def decimals(%{type: :layer_1, chain: "KUJI"}), do: 6
  def decimals(%{type: :layer_1, chain: "LTC"}), do: 8
  def decimals(%{type: :layer_1, chain: "NOBLE", ticker: "USDY"}), do: 18
  def decimals(%{type: :layer_1, chain: "NOBLE"}), do: 6
  def decimals(%{type: :layer_1, chain: "XRP"}), do: 6
  def decimals(_), do: 8

  def type(str) do
    cond do
      String.starts_with?(str, "THOR.") -> :native
      String.match?(str, ~r/^[A-Z]+\./) -> :layer_1
      String.match?(str, ~r/^[A-Z]+\//) -> :synth
      String.match?(str, ~r/^[A-Z]+~/) -> :trade
      String.match?(str, ~r/^[A-Z]+-/) -> :secured
      true -> :native
    end
  end

  def to_native(%{id: "THOR.RUNE"}), do: {:ok, "rune"}
  def to_native(%{id: "THOR.RUJI"}), do: {:ok, "x/ruji"}
  def to_native(%{id: "THOR.TCY"}), do: {:ok, "tcy"}
  def to_native(%{id: "THOR." <> _ = id}), do: {:ok, String.downcase(id)}
  def to_native(%{id: "x/" <> _ = denom}), do: {:ok, denom}

  def to_native(%{type: "SECURED", chain: chain, symbol: symbol}) do
    {:ok, String.downcase(chain) <> "-" <> String.downcase(symbol)}
  end

  def to_native(_), do: {:ok, nil}

  def to_layer1(%Asset{chain: "THOR"}), do: nil

  def to_layer1(%Asset{id: id} = a) do
    %{a | type: :layer_1, id: String.replace(id, ~r/[\.\-\/]/, ".", global: false)}
  end

  def to_secured(%Asset{chain: "THOR"}), do: nil

  def to_secured(%Asset{id: id} = a) do
    %{a | type: :secured, id: String.replace(id, ~r/[\.\-\/]/, "-", global: false)}
  end

  @doc """
  Converts a denom string to a THORChain asset - native token or

  This will only convert
  """
  def from_denom("rune") do
    {:ok, %Asset{id: "THOR.RUNE", type: :native, chain: "THOR", symbol: "RUNE", ticker: "RUNE"}}
  end

  def from_denom("tcy") do
    {:ok, %Asset{id: "THOR.TCY", type: :native, chain: "THOR", symbol: "TCY", ticker: "TCY"}}
  end

  def from_denom("thor." <> symbol) do
    symbol = String.upcase(symbol)

    {:ok,
     %Asset{id: "THOR.#{symbol}", type: :native, chain: "THOR", symbol: symbol, ticker: symbol}}
  end

  def from_denom("x/staking-x/" <> id = denom) do
    {:ok,
     %Asset{
       id: denom,
       type: :native,
       chain: "THOR",
       symbol: "s" <> String.upcase(id),
       ticker: "s" <> String.upcase(id)
     }}
  end

  def from_denom("x/bow-xyk-" <> id = denom) do
    with %{config: %{"strategy" => %{"xyk" => %{"x" => x, "y" => y}}}} <-
           Bow
           |> Deployments.list_targets()
           |> Enum.find(fn %{config: %{"strategy" => %{"xyk" => %{"x" => x, "y" => y}}}} ->
             # `-` is used as a separator for the xyk denom as well as secured assets
             String.downcase("#{x}-#{y}") == String.downcase(id)
           end),
         {:ok, x} <- from_denom(x),
         {:ok, y} <- from_denom(y) do
      {:ok,
       %Asset{
         id: denom,
         type: :native,
         chain: "THOR",
         symbol: "#{x.symbol}/#{y.symbol} LP",
         ticker: "#{x.ticker}/#{y.ticker} LP"
       }}
    else
      _ -> {:error, :invalid_denom_string}
    end
  end

  def from_denom("x/ruji") do
    {:ok,
     %Asset{
       id: "THOR.RUJI",
       type: :native,
       chain: "THOR",
       symbol: "RUJI",
       ticker: "RUJI"
     }}
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
    case denom |> String.upcase() |> String.split(@delimiters, parts: 2) do
      [chain, symbol] ->
        [ticker | _] = String.split(symbol, "-")

        {:ok,
         %Asset{
           id: String.upcase(denom),
           type: type(String.upcase(denom)),
           chain: if(chain == "BNB", do: "BSC", else: chain),
           symbol: symbol,
           ticker: ticker
         }}

      _ ->
        {:error, "Invalid Denom #{denom}"}
    end
  end

  def short_id(%{chain: chain, ticker: ticker}), do: "#{chain}.#{ticker}"

  @doc """
  Parses a comma-separated string of coin amounts into a map of `denom => amount`.

  ## Examples

      iex> parse_coins("1000uatom")
      {:ok, %{"uatom" => "1000"}}

      iex> parse_coins("0.5x/ruji,42.0uatom")
      {:ok, %{"x/ruji" => "0.5", "uatom" => "42.0"}}

      iex> parse_coins(".25test-token,100foo/bar")
      {:ok, %{"test-token" => ".25", "foo/bar" => "100"}}

      iex> parse_coins("invalid")
      {:error, :invalid_denom_format}
  """

  def parse_coins(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&Regex.run(@coin_regex, &1))
    |> Enum.reduce_while(%{}, fn
      [_, amount, denom], acc -> {:cont, Map.put(acc, denom, String.to_integer(amount))}
      _, _ -> {:halt, {:error, :invalid_denom_format}}
    end)
    |> case do
      {:error, _} = error -> error
      map -> {:ok, map}
    end
  end

  def query_match(query, %{ticker: b}, %{ticker: q}) do
    case parse_query_parts(query) do
      [part] ->
        matches(part, b) or matches(part, q)

      [part1, part2] ->
        matches(part1, b) and matches(part2, q)

      _ ->
        true
    end
  end

  defp matches(nil, _target), do: true
  defp matches("*", _target), do: true

  defp matches(query, target) do
    target
    |> String.downcase()
    |> String.contains?(String.downcase(query))
  end

  defp parse_query_parts(nil), do: []
  defp parse_query_parts(""), do: []

  defp parse_query_parts(query) do
    Regex.split(~r/[\s\-\/]/, query, trim: true)
  end

  def load_metadata(%Asset{type: :native} = asset) do
    with {:ok, metadata} <- Metadata.load_metadata(asset) do
      {:ok, %{metadata | decimals: decimals(asset)}}
    end
  end

  def load_metadata(%Asset{ticker: ticker} = asset) do
    {:ok, %{symbol: ticker, decimals: decimals(asset)}}
  end
end
