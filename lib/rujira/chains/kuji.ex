alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
import Cosmos.Bank.V1beta1.Query.Stub

defmodule Rujira.Chains.Kuji do
  defstruct []

  def connection(%__MODULE__{}) do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect("kujira-grpc.bryanlabs.net", 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end

  def map_coin(%{
        denom: "ukuji",
        amount: amount
      }) do
    %{asset: "KUJI.KUJI", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji",
        amount: amount
      }) do
    %{asset: "KUJI.RKUJI", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn",
        amount: amount
      }) do
    %{asset: "KUJI.FUZN", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink",
        amount: amount
      }) do
    %{asset: "KUJI.WINK", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk",
        amount: amount
      }) do
    %{asset: "KUJI.NSTK", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/uauto",
        amount: amount
      }) do
    %{asset: "KUJI.AUTO", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1gewwffxhaygxe8tacd3z9h4uyvpd2h7v9qtfmaw8jjhwalxxpd7qlqld4m/boon",
        amount: amount
      }) do
    %{asset: "KUJI.BOON", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1643jxg8wasy5cfcn7xm8rd742yeazcksqlg4d7/umnta",
        amount: amount
      }) do
    %{asset: "KUJI.MNTA", amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/unami",
        amount: amount
      }) do
    %{asset: "KUJI.NAMI", amount: amount}
  end

  def map_coin(_), do: nil
end

defimpl Rujira.Chains.Adapter, for: Rujira.Chains.Kuji do
  alias Cosmos.Base.Query.V1beta1.PageRequest

  def balances(a, address, _assets) do
    req = %QueryAllBalancesRequest{address: address, pagination: %PageRequest{limit: 100}}

    with {:ok, conn} <- Rujira.Chains.Kuji.connection(a) |> IO.inspect(),
         {:ok, %QueryAllBalancesResponse{balances: balances}} <-
           all_balances(conn, req) |> IO.inspect() do
      balances =
        Enum.reduce(balances, [], fn e, agg ->
          case Rujira.Chains.Kuji.map_coin(e) do
            nil -> agg
            x -> [x | agg]
          end
        end)

      {:ok, balances}
    end
  end
end
