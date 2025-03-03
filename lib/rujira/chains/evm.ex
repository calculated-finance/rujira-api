defmodule Rujira.Chains.Evm do
  use Appsignal.Instrumentation.Decorators
  use Memoize

  @decorate transaction_event()
  def native_balance(rpc, address) do
    with {:ok, "0x" <> hex} <-
           Ethereumex.HttpClient.eth_get_balance(address, "latest", url: rpc) do
      {:ok, String.to_integer(hex, 16)}
    else
      {:error, %{"error" => %{"message" => message}}} -> {:error, message}
      err -> err
    end
  end

  @decorate transaction_event()
  defmemo balance_of(rpc, "0x" <> address, asset) do
    [_, contract_address] = String.split(asset.symbol, "-")

    abi_encoded_data =
      "balanceOf(address)"
      |> ABI.encode([Base.decode16!(address, case: :mixed)])
      |> Base.encode16(case: :lower)

    with {:ok, "0x" <> balance_bytes} <-
           Ethereumex.HttpClient.eth_call(
             %{
               data: "0x" <> abi_encoded_data,
               to: contract_address
             },
             "latest",
             url: rpc
           ),
         {:ok, decoded_balance} <- Base.decode16(balance_bytes, case: :lower),
         [balance] <- ABI.TypeDecoder.decode_raw(decoded_balance, [{:uint, 256}]) do
      {:ok, %{asset: asset, amount: balance}}
    else
      {:error, %{"message" => message}} ->
        {:error, message}

      _ ->
        {:error, :unknown_error}
    end
  end

  @decorate transaction_event()
  def balances_of(rpc, address, assets) do
    with {:ok, balances} <-
           Task.async_stream(assets, &balance_of(rpc, address, &1))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, balance}}, {:ok, acc} -> {:ok, [balance | acc]}
             {:ok, {:error, %{"error" => %{"message" => message}}}}, _ -> {:error, message}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, balances}
    end
  end
end
