defmodule Rujira.Chains.Xrp do
  def client do
    Tesla.client(middleware())
  end

  def middleware do
    [
      {Tesla.Middleware.BaseUrl, base_url()},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers,
       [
         {"apollographql-client-name", "docs-indexers-api"},
         {"apollographql-client-version", "v1.0"}
       ]}
    ]
  end

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
          }} <- Tesla.post(client(), "/", body),
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
