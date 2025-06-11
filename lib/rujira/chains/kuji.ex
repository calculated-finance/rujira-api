defmodule Rujira.Chains.Kuji do
  alias Cosmos.Bank.V1beta1.QueryAllBalancesRequest
  alias Cosmos.Bank.V1beta1.QueryAllBalancesResponse
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Rujira.Assets
  alias Cosmos.Base.Query.V1beta1.PageRequest

  @rpc "kujira-grpc.bryanlabs.net"

  def balances(address, _assets) do
    with {:ok, conn} <- connection(),
         {:ok, balances} <- balances_page(conn, address) do
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

  def connection() do
    cred = GRPC.Credential.new(ssl: [verify: :verify_none])

    GRPC.Stub.connect(@rpc, 443,
      interceptors: [{GRPC.Client.Interceptors.Logger, level: :debug}],
      cred: cred
    )
  end

  def to_denom("KUJI"), do: {:ok, "ukuji"}

  def to_denom("RKUJI"),
    do: {:ok, "factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji"}

  def to_denom("FUZN"),
    do: {:ok, "factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn"}

  def to_denom("WINK"),
    do: {:ok, "factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink"}

  def to_denom("NSTK"),
    do: {:ok, "factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk"}

  def to_denom("AUTO"),
    do: {:ok, "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/uauto"}

  def to_denom("BOON"),
    do: {:ok, "factory/kujira1gewwffxhaygxe8tacd3z9h4uyvpd2h7v9qtfmaw8jjhwalxxpd7qlqld4m/boon"}

  def to_denom("MNTA"),
    do: {:ok, "factory/kujira1643jxg8wasy5cfcn7xm8rd742yeazcksqlg4d7/umnta"}

  def to_denom("NAMI"),
    do: {:ok, "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/unami"}

  def to_denom(_), do: {:error, :unknown_asset}

  def map_coin(%{
        denom: "ukuji",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.KUJI"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.RKUJI"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.FUZN"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.WINK"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.NSTK"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/uauto",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.AUTO"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1gewwffxhaygxe8tacd3z9h4uyvpd2h7v9qtfmaw8jjhwalxxpd7qlqld4m/boon",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.BOON"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira1643jxg8wasy5cfcn7xm8rd742yeazcksqlg4d7/umnta",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.MNTA"), amount: amount}
  end

  def map_coin(%{
        denom: "factory/kujira13x2l25mpkhwnwcwdzzd34cr8fyht9jlj7xu9g4uffe36g3fmln8qkvm3qn/unami",
        amount: amount
      }) do
    %{asset: Assets.from_string("KUJI.NAMI"), amount: amount}
  end

  def map_coin(_), do: nil
end
