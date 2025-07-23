defmodule Rujira.Chains.Osmo do
  @moduledoc """
  Implements the Osmosis adapter for Cosmos compatibility.
  """
  # Aliases
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets

  # Imports
  import Cosmos.Bank.V1beta1.Query.Stub

  @rpc "osmosis-grpc.bryanlabs.net"

  use Rujira.Chains.Cosmos.Listener, ws: "wss://osmosis-rpc.bryanlabs.net", chain: "osmo"

  def balances(address, _assets) do
    with {:ok, conn} <- connection(),
         {:ok, balances} <- balances_page(conn, address) do
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

  def balances_page(conn, address, pagination \\ %PageRequest{limit: 100})

  def balances_page(conn, address, %PageRequest{} = pagination) do
    req = %QueryAllBalancesRequest{address: address, pagination: pagination}

    with {:ok, %QueryAllBalancesResponse{balances: balances, pagination: %{next_key: next_key}}}
         when next_key != "" <-
           all_balances(conn, req),
         {:ok, next} <- balances_page(conn, address, %PageRequest{key: next_key, limit: 100}) do
      {:ok, balances ++ next}
    else
      {:ok, %QueryAllBalancesResponse{balances: balances}} -> {:ok, balances}
      {:error, %{message: message}} -> {:error, message}
    end
  end

  def connection do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect(@rpc, 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end

  def to_denom("OSMO"), do: {:ok, "uosmo"}

  def to_denom("LVN"),
    do: {:ok, "factory/osmo1mlng7pz4pnyxtpq0akfwall37czyk9lukaucsrn30ameplhhshtqdvfm5c/ulvn"}

  def to_denom(_), do: {:error, :unknown_asset}

  def map_coin(%{denom: "uosmo", amount: amount}) do
    %{asset: Assets.from_string("OSMO.OSMO"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/osmo1mlng7pz4pnyxtpq0akfwall37czyk9lukaucsrn30ameplhhshtqdvfm5c/ulvn",
        amount: amount
      }) do
    %{asset: Assets.from_string("OSMO.LVN"), amount: amount}
  end

  def map_coin(_), do: nil
end
