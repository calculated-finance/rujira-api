defmodule Rujira.Assets do
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

  def decimals("AVAX" <> _), do: 18
  def decimals("BCH" <> _), do: 8
  def decimals("BTC" <> _), do: 8
  def decimals("BSC" <> _), do: 18
  def decimals("DOGE" <> _), do: 8
  def decimals("ETH" <> _), do: 18
  def decimals("GAIA" <> _), do: 6
  def decimals("LTC" <> _), do: 8
  def decimals("THOR" <> _), do: 6

  def type(str) do
    cond do
      String.match?(str, Regex.compile!("^[A-Z]+\.")) -> :layer_1
      String.match?(str, Regex.compile!("^[A-Z]+-")) -> :secured
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

  def to_native(asset) do
    case String.split(asset, "-", parts: 2) do
      [chain, token] -> {:ok, String.downcase(chain) <> "-" <> String.downcase(token)}
      _ -> {:ok, nil}
    end
  end
end
