alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
import Cosmos.Bank.V1beta1.Query.Stub

defmodule Rujira.Chains.Gaia do
  defstruct []

  def connection(%__MODULE__{}) do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect("cosmos-grpc.bryanlabs.net", 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end

  def to_denom("GAIA.ATOM"), do: {:ok, "uatom"}

  def to_denom("GAIA.KUJI"),
    do: {:ok, "ibc/4CC44260793F84006656DD868E017578F827A492978161DA31D7572BCB3F4289"}

  def to_denom("GAIA.RKUJI"),
    do: {:ok, "ibc/50A69DC508ACCADE2DAC4B8B09AA6D9C9062FCBFA72BB4C6334367DECD972B06"}

  def to_denom("GAIA.FUZN"),
    do: {:ok, "ibc/6BBBB4B63C51648E9B8567F34505A9D5D8BAAC4C31D768971998BE8C18431C26"}

  def to_denom("GAIA.WINK"),
    do: {:ok, "ibc/4363FD2EF60A7090E405B79A6C4337C5E9447062972028F5A99FB041B9571942"}

  def to_denom("GAIA.NSTK"),
    do: {:ok, "ibc/0B99C4EFF1BD05E56DEDEE1D88286DB79680C893724E0E7573BC369D79B5DDF3"}

  def to_denom("GAIA.LVN"),
    do: {:ok, "ibc/6C95083ADD352D5D47FB4BA427015796E5FEF17A829463AD05ECD392EB38D889"}

  def to_denom(_), do: {:error, :unknown_asset}

  def map_coin(%{denom: "uatom", amount: amount}) do
    %{asset: "GAIA.ATOM", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/4CC44260793F84006656DD868E017578F827A492978161DA31D7572BCB3F4289",
        amount: amount
      }) do
    %{asset: "GAIA.KUJI", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/50A69DC508ACCADE2DAC4B8B09AA6D9C9062FCBFA72BB4C6334367DECD972B06",
        amount: amount
      }) do
    %{asset: "GAIA.RKUJI", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/6BBBB4B63C51648E9B8567F34505A9D5D8BAAC4C31D768971998BE8C18431C26",
        amount: amount
      }) do
    %{asset: "GAIA.FUZN", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/4363FD2EF60A7090E405B79A6C4337C5E9447062972028F5A99FB041B9571942",
        amount: amount
      }) do
    %{asset: "GAIA.WINK", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/0B99C4EFF1BD05E56DEDEE1D88286DB79680C893724E0E7573BC369D79B5DDF3",
        amount: amount
      }) do
    %{asset: "GAIA.NSTK", amount: amount}
  end

  def map_coin(%{
        denom: "ibc/6C95083ADD352D5D47FB4BA427015796E5FEF17A829463AD05ECD392EB38D889",
        amount: amount
      }) do
    %{asset: "GAIA.LVN", amount: amount}
  end

  def map_coin(_), do: nil
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Gaia do
  def balances(a, address, _assets) do
    req = %QueryAllBalancesRequest{address: address}

    with {:ok, conn} <- Rujira.Chains.Gaia.connection(a),
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
end
