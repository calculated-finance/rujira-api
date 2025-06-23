defmodule Rujira.Chains.Bch do
  @moduledoc """
  Implements the Bitcoin Cash adapter for UTXO compatibility.
  """
  use Rujira.Chains.Utxo, chain: "bitcoincash", asset: "BCH.BCH", decimals: 8
end
