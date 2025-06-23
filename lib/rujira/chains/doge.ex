defmodule Rujira.Chains.Doge do
  @moduledoc """
  Implements the Dogecoin adapter for UTXO compatibility.
  """
  use Rujira.Chains.Utxo, chain: "dogecoin", asset: "DOGE.DOGE", decimals: 8
end
