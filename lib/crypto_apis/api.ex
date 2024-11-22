defmodule CryptoApis.Api do
  @api_url "https://rest.cryptoapis.io/blockchain-data"

  def get_balance(network, address, decimals) do
    url =
      Finch.build(
        :get,
        "#{@api_url}/#{network}/mainnet/addresses/#{address}/balance",
        [
          {"X-API-Key", "e2eaa2c60450748777f07f991e26baaec9b156f9"},
          {"Content-Type", "application/json"}
        ]
      )

    with {:ok, %{status: 200, body: body}} <- Finch.request(url, Rujira.Finch),
         {:ok,
          %{
            "data" => %{"item" => %{"confirmedBalance" => %{"amount" => amount}}}
          }} <- Jason.decode(body),
         {balance, ""} <- Float.parse(amount) do
      {:ok, trunc(balance * 10 ** decimals)}
    else
      :error ->
        {:error, :invalid_balance}

      err ->
        handle_error(err)
    end
  end

  defp handle_error({:ok, %{status: status, body: body}}) do
    case Jason.decode(body) do
      {:ok, %{"error" => %{"code" => code}}} ->
        {:error, "error code #{status}: #{code}"}

      err ->
        err
    end
  end

  defp handle_error({:error, err}), do: {:error, err}
end
