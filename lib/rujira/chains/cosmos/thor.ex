defmodule Rujira.Chains.Cosmos.Thor do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub

  def balances(address) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, _conn} <- connection(),
         {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Rujira.Grpc.Client.stub(fn channel -> all_balances(channel, req) end) do
      {:ok, balances}
    end
  end

  def connection() do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect("thornode-devnet-grpc.bryanlabs.net", 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end
end
