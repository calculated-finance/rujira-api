defmodule Rujira.Balances.Btc do
  def fetch_balance(chain, address) do
    Rujira.Blockstream.Api.get_balance(address)
  end
end
