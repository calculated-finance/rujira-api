defmodule Rujira.Chains.Terra2 do
  @moduledoc """
  Implements the Terra2 adapter for Cosmos compatibility.
  """
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  alias Cosmos.Base.Query.V1beta1.PageRequest
  alias Rujira.Assets
  alias Rujira.Chains.Cosmos.Delegations
  alias Rujira.Chains.Cosmos.Vesting

  import Cosmos.Bank.V1beta1.Query.Stub

  @rpc "terra2-grpc.bryanlabs.net"

  @symbol_traces %{
    "LUNA" => "uluna",
    "USDC" => "ibc/2C962DAB9F57FE0921435426AE75196009FAA1981BF86991203C8411F8980FDB",
    "ASTRO" => "ibc/8D8A7F7253615E5F76CB6252A1E1BD921D5EDB7BBAAF8913FB1C77FF125D9995",
    "USDC.axl" => "ibc/B3504E092456BA618CC28AC671A71FB08C6CA0FD0BE7C8A5B5A3E2DD933CC9E4",
    "ROAR" => "terra1lxx40s29qvkrcj8fsa3yzyehy7w50umdvvnls2r830rys6lu2zns63eelv",
    "wBTC.axl" => "ibc/05D299885B07905B6886F554B39346EA6761246076A1120B1950049B92B922DD",
    "ATOM" => "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2",
    "wBTC" => "ibc/CF57A83CED6CEC7D706631B5DC53ABC21B7EDA7DF7490732B4361E6D5DD19C73",
    "USDT" => "ibc/9B19062D46CAB50361CE9B0A3E6D0A7A53AC9E7CB361F32A73CC733144A9A9E5",
    "dATOM" => "ibc/223FF539430381ADAB3A66AC4822E253C3F845E9841F17FEEC207B3AA9F8D915",
    "EURe" => "ibc/8D52B251B447B7160421ACFBD50F6B0ABE5F98D2C404B03701130F12044439A1",
    "wstETH" => "ibc/A356EC90DC3AE43D485514DA7260EDC7ABB5CFAA0654CE2524C739392975AD3C",
    "USDT.axl" => "ibc/CBF67A2BCF6CAE343FDF251E510C8E18C361FC02B23430C121116E0811835DEF",
    "wSOL" => "terra1ctelwayk6t2zu30a8v9kdg3u2gr0slpjdfny5pjp7m3tuquk32ysugyjdg",
    "stATOM" => "ibc/FD9DBF0DB4D301313195159303811FD2FD72185C4B11A51659EFCD49D7FF1228",
    "wBNB" => "terra1xc7ynquupyfcn43sye5pfmnlzjcw2ck9keh0l2w2a4rhjnkp64uq4pr388",
    "WETH.axl" => "ibc/BC8A77AFBD872FDC32A348D3FB10CC09277C266CFE52081DE341C7EC6752E674",
    "INJ" => "ibc/25BC59386BB65725F735EFC0C369BB717AA8B5DAD846EAF9CBF5D0F18F207211"
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
      {:ok, token} -> %{asset: Assets.from_string("TERRA2.#{token}"), amount: amount}
      :error -> nil
    end
  end

  def get_vesting_account(address) do
    with {:ok, conn} <- connection(),
         {:ok, %{vesting_periods: vesting_periods} = account} <-
           Vesting.get_vesting_account(address, conn) do
      {:ok, %{account | vesting_periods: Enum.map(vesting_periods, &parse_vesting_period/1)}}
    end
  end

  def parse_vesting_period(%{end_time: end_time, balances: balances}) do
    balances =
      balances
      |> Enum.map(&map_coin/1)
      |> Enum.filter(fn x -> x != nil end)

    %{end_time: end_time, balances: balances}
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
