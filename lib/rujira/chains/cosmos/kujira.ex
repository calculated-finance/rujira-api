defmodule Rujira.Chains.Cosmos.Kujira do
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  import Cosmos.Bank.V1beta1.Query.Stub

  @tokens [
    "ukuji",
    "factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn",
    "factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink",
    "factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk",
    "factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji"
  ]

  def balances(address) do
    with {:ok, conn} <- connection(),
         {:ok, balances} <-
           Task.async_stream(@tokens, &balance_of(conn, address, &1))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, %{amount: "0"}}}, {:ok, acc} ->
               {:ok, acc}

             {:ok, {:ok, %{denom: denom, amount: amount}}}, {:ok, acc} ->
               {:ok, [%{denom: denom, amount: amount} | acc]}

             _, {:error, err} ->
               {:error, err}

             error, _ ->
               error
           end) do
      {:ok, balances}
    else
      {:error, %{message: message}} -> {:error, message}
      error -> error
    end
  end

  def balance_of(conn, address, denom) do
    req = %QueryBalanceRequest{address: address, denom: denom}

    with {:ok, %QueryBalanceResponse{balance: balance}} <- balance(conn, req) do
      {:ok, balance}
    else
      {:error, %{message: message}} -> {:error, message}
      error -> error
    end
  end

  defp connection() do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect("kujira-grpc.bryanlabs.net", 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end
end
