defmodule Rujira.Chains.Cosmos.Thor do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub

  def balances(address) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           Thorchain.Grpc.Client.stub(&all_balances/2, req) do
      {:ok, balances}
    end
  end
end
