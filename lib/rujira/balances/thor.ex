defmodule Rujira.Balances.Thor do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub

  def fetch_balances(address) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, conn} <- connection(),
         {:ok, %QueryAllBalancesResponse{balances: balances}} <- all_balances(conn, req) do
      {:ok, balances}
    else
      {:error, %{message: message}} -> {:error, message}
    end
  end

  defp connection() do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect("thornode-grpc.defiantlabs.net", 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end
end
