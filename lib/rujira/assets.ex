defmodule Rujira.Assets do
  @moduledoc """
  Interfaces for interacting with THORChain Asset values
  """

  def to_symbol(str) do
    # TODO: suport more delimiters
    [_, v | _] = String.split(str, ".")
    [sym | _] = String.split(v, "-")
    sym
  end

  def decimals("AVAX." <> _), do: 18
  def decimals("BCH." <> _), do: 8
  def decimals("BTC." <> _), do: 8
  def decimals("DOGE." <> _), do: 8
  def decimals("ETH." <> _), do: 18
  def decimals("GAIA." <> _), do: 6
  def decimals("LTC." <> _), do: 8
  def decimals("THOR." <> _), do: 6
end
