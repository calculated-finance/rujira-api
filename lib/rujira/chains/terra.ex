defmodule Rujira.Chains.Terra do
  @moduledoc """
  Implements the Terra adapter for Cosmos compatibility.
  """
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Chains.Cosmos.Delegations
  alias Rujira.Chains.Cosmos.Vesting

  import Cosmos.Bank.V1beta1.Query.Stub

  @rpc "terra-grpc.bryanlabs.net"

  @symbol_traces %{
    "LUNC" => "uluna",
    "OSMO" => "ibc/0471F1C4E7AFD3F07702BEF6DC365268D64570F7C1FDC98EA6098DD6DE59817B",
    "ATOM" => "ibc/18ABA66B791918D51D33415DA173632735D830E2E77E63C91C11D3008CFD5262"
  }

  @trace_symbols for {token, denom} <- @symbol_traces, into: %{}, do: {denom, token}

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
      {:ok, token} -> %{asset: Assets.from_string("TERRA.#{token}"), amount: amount}
      :error -> nil
    end
  end

  def get_vesting_account(address) do
    with {:ok, conn} <- connection(),
         {:ok, %{vesting_periods: vesting_periods} = account} <-
           Vesting.get_vesting_account(address, conn) do
      %{account | vesting_periods: Enum.map(vesting_periods, &parse_vesting_period/1)}
    end
  end

  def parse_vesting_period(%{end_time: end_time, balances: balances}) do
    with {:ok, end_time} <- DateTime.from_unix(end_time) do
      balances =
        balances
        |> Enum.map(&map_coin/1)
        |> Enum.reduce([], fn {:ok, asset}, agg ->
          [asset | agg]
        end)

      %{end_time: end_time, balances: balances}
    end
  end

  def get_delegations(address) do
    with {:ok, conn} <- connection(),
         {:ok, delegations} <-
           Delegations.get_delegations(address, conn) do
      delegations =
        delegations
        |> Enum.map(fn %{balance: balance} = delegation ->
          %{delegation | balance: map_coin(balance)}
        end)

      {:ok, delegations}
    end
  end

  def get_unbonding_delegations(address) do
    with {:ok, conn} <- connection(),
         {:ok, unbondings} <-
           Delegations.get_unbonding_delegations(address, conn) do
      unbondings =
        unbondings
        |> Enum.map(fn %{entries: entries} = unbonding ->
          entries =
            entries
            |> Enum.map(fn %{balance: balance} = entry ->
              %{entry | balance: map_coin(%{denom: "uluna", amount: balance})}
            end)
            |> Enum.filter(fn x -> x != nil end)

          %{unbonding | entries: entries}
        end)

      {:ok, unbondings}
    end
  end
end
