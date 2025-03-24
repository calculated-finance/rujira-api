defmodule Rujira.Chains.Gaia do
  use GenServer
  alias Rujira.Assets
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub

  @rpc "cosmoshub.lavenderfive.com"

  @symbol_traces %{
    "ATOM" => "uatom",
    "AUTO" => "ibc/7D20C448700E7C56DC4577DA46666BA7993AEC6BFA223E67FA23CC4333B28745",
    "BOON" => "ibc/08520C5EF68E2F04784EAC80F5B4A4342B5301701E2B74426AAECFB20E9139DB",
    "FUZN" => "ibc/6BBBB4B63C51648E9B8567F34505A9D5D8BAAC4C31D768971998BE8C18431C26",
    "KUJI" => "ibc/4CC44260793F84006656DD868E017578F827A492978161DA31D7572BCB3F4289",
    "LVN" => "ibc/6C95083ADD352D5D47FB4BA427015796E5FEF17A829463AD05ECD392EB38D889",
    "MNTA" => "ibc/CF52BFC8A11248F05151BFEC0FB033C3531E40C7BAFC72E277F49346EF76E981",
    "NAMI" => "ibc/4622E82B845FFC6AA8B45C1EB2F507133A9E876A5FEA1BA64585D5F564405453",
    "NSTK" => "ibc/0B99C4EFF1BD05E56DEDEE1D88286DB79680C893724E0E7573BC369D79B5DDF3",
    "RKUJI" => "ibc/50A69DC508ACCADE2DAC4B8B09AA6D9C9062FCBFA72BB4C6334367DECD972B06",
    "WINK" => "ibc/4363FD2EF60A7090E405B79A6C4337C5E9447062972028F5A99FB041B9571942"
  }

  @trace_symbols for {token, denom} <- @symbol_traces, into: %{}, do: {denom, token}

  def balances(address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, conn} <- connection(),
         {:ok, %QueryAllBalancesResponse{balances: balances}} <- all_balances(conn, req) do
      balances =
        Enum.reduce(balances, [], fn e, agg ->
          case Rujira.Chains.Gaia.map_coin(e) do
            nil -> agg
            x -> [x | agg]
          end
        end)

      {:ok, balances}
    end
  end

  def start_link(_) do
    Supervisor.start_link([__MODULE__.Websocket, __MODULE__.Listener],
      strategy: :one_for_one
    )
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def connection() do
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
      {:ok, token} -> %{asset: Assets.from_string("GAIA.#{token}"), amount: amount}
      :error -> nil
    end
  end
end
