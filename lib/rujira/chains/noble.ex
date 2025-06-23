defmodule Rujira.Chains.Noble do
  @moduledoc """
  Implements the Noble adapter for Cosmos compatibility.
  """
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Rujira.Assets

  import Cosmos.Bank.V1beta1.Query.Stub

  use Rujira.Chains.Cosmos.Listener, ws: "wss://noble-rpc.bryanlabs.net", chain: "noble"

  @rpc "noble-grpc.bryanlabs.net"

  @symbol_traces %{
    "USDC" => "uusdc",
    "EURE" => "eeure",
    "USDY" => "ausdy"
  }

  @trace_symbols for {token, denom} <- @symbol_traces, into: %{}, do: {denom, token}

  def balances(address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, conn} <- connection(),
         {:ok, %QueryAllBalancesResponse{balances: balances}} <- all_balances(conn, req) do
      balances =
        Enum.reduce(balances, [], fn e, agg ->
          case map_coin(e) do
            nil -> agg
            x -> [x | agg]
          end
        end)

      {:ok, balances}
    end
  end

  def connection do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect(@rpc, 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end

  def to_denom(token) do
    case Map.fetch(@symbol_traces, token) do
      {:ok, denom} -> {:ok, denom}
      :error -> {:error, :unknown_asset}
    end
  end

  def map_coin(%{denom: denom, amount: amount}) do
    case Map.fetch(@trace_symbols, denom) do
      {:ok, token} -> %{asset: Assets.from_string("NOBLE.#{token}"), amount: amount}
      :error -> nil
    end
  end
end
