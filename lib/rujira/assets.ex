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
end
