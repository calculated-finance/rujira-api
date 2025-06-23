defmodule Rujira.Chains.Ltc do
  @moduledoc """
  Implements the Litecoin adapter for UTXO compatibility.
  """
  use Rujira.Chains.Utxo, chain: "litecoin", asset: "LTC.LTC", decimals: 8
end
