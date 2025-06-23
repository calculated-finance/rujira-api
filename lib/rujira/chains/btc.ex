defmodule Rujira.Chains.Btc do
  @moduledoc """
  Implements the Bitcoin adapter for UTXO compatibility.
  """
  use Rujira.Chains.Utxo, chain: "bitcoin", asset: "BTC.BTC", decimals: 8
end
