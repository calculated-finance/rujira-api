defmodule Rujira.Chains.Xrp do
  use Tesla

  plug Tesla.Middleware.BaseUrl, base_url()
  plug Tesla.Middleware.Headers, [{"Content-Type", "application/json"}]
  plug Tesla.Middleware.JSON

  def account_info(account) do
    body = %{
      "method" => "account_info",
      "params" => [
        %{"account" => account, "strict" => true, "ledger_index" => "current", "queue" => true}
      ],
      "id" => 1,
      "jsonrpc" => "2.0"
    }

    with {:ok,
          %{
            body: %{
              "result" => %{
                "account_data" => %{
                  "Account" => account,
                  "Balance" => balance
                  # "Flags" => flags,
                  # "LedgerEntryType" => ledger_entry_type,
                  # "OwnerCount" => owner_count,
                  # "PreviousTxnID" => previous_tx_id,
                  # "PreviousTxnLgrSeq" => previous_tx_lgr_seq,
                  # "Sequence" => seq,
                  # "index" => idx
                }
              }
            }
          }} <- post("/", body),
         {balance, ""} <- Integer.parse(balance) do
      {:ok, %{account: account, balance: balance}}
    end
  end

  defp base_url do
    Application.get_env(:rujira, __MODULE__)[:http] ||
      raise "Missing XRP HTTP base URL in config"
  end

  def balances(address, _) do
    with {:ok, %{balance: balance}} <- account_info(address) do
      {:ok, [%{asset: Rujira.Assets.from_string("XRP.XRP"), amount: balance}]}
    end
  end
end
