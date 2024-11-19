defmodule Rujira.Balances.Evm do
  def fetch_balance(chain, address) do
    with {:ok, rpc} <- rpc_for(chain),
         {:ok, "0x" <> hex} =
           Ethereumex.HttpClient.eth_get_balance(address, "latest", url: rpc) do
      {:ok, String.to_integer(hex, 16)}
    end
  end

  defp rpc_for(chain) do
    case chain do
      :avax -> {:ok, "https://api.avax.network/ext/bc/C/rpc"}
      :eth -> {:ok, "https://ethereum-rpc.publicnode.com"}
      _ -> {:error, :no_rpc}
    end
  end
end
