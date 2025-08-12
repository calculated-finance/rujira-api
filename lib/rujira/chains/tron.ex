defmodule Rujira.Chains.Tron do
  @moduledoc """
  Implements the Tron adapter.
  """
  @rpc "https://tron-evm-rpc.publicnode.com"
  # @ws "wss://tron-evm-rpc.publicnode.com"
  # @retry_delay 60_000
  # @transfer "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"

  def client do
    Tesla.client(middleware())
  end

  def middleware do
    [
      {Tesla.Middleware.BaseUrl, base_url()},
      Tesla.Middleware.JSON
    ]
  end

  def native_balance(address) do
    body = %{jsonrpc: "2.0", method: "eth_getBalance", params: [address, "latest"], id: 1}

    with {:ok,
          %{
            body: %{"result" => balance}
          }} <- Tesla.post(client(), "/", body),
         {:ok, balance} <- parse_hex_amount(balance) do
      {:ok, %{account: address, balance: balance}}
    else
      {:ok, %{body: %{"result" => %{"error" => "actNotFound"}}}} ->
        {:ok, %{account: address, balance: 0}}

      {:ok, %{body: %{"error" => error}}} ->
        {:error, error}

      other ->
        other
    end
  end

  def balances_of(address, assets) do
    Rujira.Enum.reduce_async_while_ok(assets, fn asset ->
      case balance_of(address, asset) do
        {:ok, balance} -> {:ok, %{asset: asset, amount: balance}}
        {:error, %{"error" => %{"message" => message}}} -> {:error, message}
        {:error, error} -> {:error, error}
      end
    end)
  end

  def balance_of(address, contract) do
    abi_encoded_data =
      "balanceOf(address)"
      |> ABI.encode([Base.decode16!(address, case: :mixed)])
      |> Base.encode16(case: :lower)

    body = %{
      jsonrpc: "2.0",
      method: "eth_call",
      params: [%{"to" => contract, "data" => "0x" <> abi_encoded_data}, "latest"],
      id: 1
    }

    with {:ok,
          %{
            body: %{"result" => balance}
          }} <- Tesla.post(client(), "/", body),
         {:ok, balance} <- parse_hex_amount(balance) do
      {:ok, %{account: address, balance: balance}}
    else
      {:ok, %{body: %{"result" => %{"error" => "actNotFound"}}}} ->
        {:ok, %{account: address, balance: 0}}

      {:ok, %{body: %{"error" => error}}} ->
        {:error, error}

      other ->
        other
    end
  end

  defp base_url do
    Application.get_env(:rujira, __MODULE__)[:http] || @rpc
  end

  def balances(address, assets) do
    with {:ok, address} <- address(address),
         {:ok, %{balance: balance}} <- native_balance(address),
         {:ok, assets_balance} <- balances_of(address, assets) do
      {:ok, [%{asset: Rujira.Assets.from_string("TRON.TRX"), amount: balance} | assets_balance]}
    end
  end

  def address(address) do
    with {:ok, decoded} <- B58.decode58(address),
         <<0x41, addr::binary-20, _checksum::binary-4>> <- decoded do
      {:ok, "0x" <> Base.encode16(addr, case: :lower)}
    else
      _ -> {:error, "Invalid Tron address"}
    end
  end

  def parse_hex_amount("0x" <> hex) do
    {value, ""} = Integer.parse(hex, 16)
    {:ok, value}
  end
end
