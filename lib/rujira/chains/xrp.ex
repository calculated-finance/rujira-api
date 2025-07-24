defmodule Rujira.Chains.Xrp do
  @moduledoc """
  Implements the XRP Ledger (XRP) adapter for account-based blockchain interactions.
  """
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
                }
              }
            }
          }} <- Tesla.post(client(), "/", body),
         {balance, ""} <- Integer.parse(balance) do
      {:ok, %{account: account, balance: balance}}
    else
      {:ok, %{body: %{"result" => %{"error" => "actNotFound"}}}} ->
        {:ok, %{account: account, balance: 0}}

      {:ok, %{body: %{"result" => %{"error_message" => error}}}} ->
        {:error, error}

      other ->
        other
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
