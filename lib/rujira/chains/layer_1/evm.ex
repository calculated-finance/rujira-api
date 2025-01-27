defmodule Rujira.Chains.Layer1.Evm do
  def native_balance(rpc, address, asset) do
    with {:ok, "0x" <> hex} <-
           Ethereumex.HttpClient.eth_get_balance(address, "latest", url: rpc) do
      {:ok, [%{asset: asset, amount: String.to_integer(hex, 16)}]}
    end
  end

  def balance_of(rpc, "0x" <> address, assets) do
    abi_encoded_data =
      ABI.encode("balanceOf(address)", [Base.decode16!(address, case: :mixed)])
      |> Base.encode16(case: :lower)

    with {:ok, contract_address} <- Rujira.Assets.to_native(assets),
         {:ok, "0x" <> balance_bytes} <-
           Ethereumex.HttpClient.eth_call(
             %{
               data: "0x" <> abi_encoded_data,
               to: contract_address
             },
             "latest",
             url: rpc
           ),
         {:ok, decoded_balance} <- Base.decode16(balance_bytes, case: :lower) do
      balance =
        decoded_balance
        |> ABI.TypeDecoder.decode_raw([{:uint, 256}])
        |> List.first()

      {:ok, [%{asset: assets, amount: balance}]}
    end
  end

  def balances_of(rpc, "0x" <> address, assets) do
    with {:ok, balances} <-
           Task.async_stream(assets, &balance_of(rpc, "0x" <> address, &1))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, balance}}, {:ok, acc} -> {:ok, [balance | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, balances}
    end
  end
end
