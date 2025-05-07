defmodule Rujira.Staking.Pool do
  use Memoize
  import Ecto.Query

  defmodule Summary do
    defstruct [
      :id,
      :apr,
      :revenue,
      :revenue1,
      :revenue7,
      :revenue30
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            apr: Decimal.t(),
            revenue: list(map()),
            revenue1: integer(),
            revenue7: integer(),
            revenue30: integer()
          }
  end

  defmodule Status do
    defstruct [
      :id,
      :account_bond,
      :account_revenue,
      :liquid_bond_shares,
      :liquid_bond_size,
      :pending_revenue
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            account_bond: integer(),
            account_revenue: integer(),
            liquid_bond_shares: integer(),
            liquid_bond_size: integer(),
            pending_revenue: integer()
          }

    @spec from_query(String.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :parse_error}
    def from_query(address, %{
          "account_bond" => account_bond,
          "assigned_revenue" => account_revenue,
          "liquid_bond_shares" => liquid_bond_shares,
          "liquid_bond_size" => liquid_bond_size,
          "undistributed_revenue" => pending_revenue
        }) do
      with {account_bond, ""} <- Integer.parse(account_bond),
           {account_revenue, ""} <- Integer.parse(account_revenue),
           {liquid_bond_shares, ""} <- Integer.parse(liquid_bond_shares),
           {liquid_bond_size, ""} <- Integer.parse(liquid_bond_size),
           {pending_revenue, ""} <- Integer.parse(pending_revenue) do
        {:ok,
         %__MODULE__{
           id: address,
           account_bond: account_bond,
           account_revenue: account_revenue,
           liquid_bond_shares: liquid_bond_shares,
           liquid_bond_size: liquid_bond_size,
           pending_revenue: pending_revenue
         }}
      else
        _ -> {:error, :parse_error}
      end
    end
  end

  defstruct [
    :id,
    :address,
    :bond_denom,
    :revenue_denom,
    :revenue_converter,
    :status
  ]

  @type revenue_converter_t :: {String.t(), binary(), integer()}

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          bond_denom: String.t(),
          revenue_denom: String.t(),
          revenue_converter: revenue_converter_t(),
          status: :not_loaded | Status.t()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()}
  def from_config(address, %{
        "bond_denom" => bond_denom,
        "revenue_denom" => revenue_denom,
        "revenue_converter" => revenue_converter
      }) do
    {:ok,
     %__MODULE__{
       id: address,
       address: address,
       bond_denom: bond_denom,
       revenue_denom: revenue_denom,
       revenue_converter: revenue_converter,
       status: :not_loaded
     }}
  end

  def summary(%__MODULE__{} = pool) do
    with {:ok, %{status: %{account_bond: account_bond, liquid_bond_size: liquid_bond_size}}} <-
           Rujira.Staking.load_pool(pool),
         {:ok, %{price: price}} <- Rujira.Prices.get("RUJI") do
      revenue = get_revenue(pool, 30)
      revenue30 = sum_revenue(revenue, 30)

      value =
        (account_bond + liquid_bond_size)
        |> Decimal.new()
        |> Decimal.mult(price)
        |> Decimal.div(Decimal.new(1_000_000_000_000))

      apr =
        revenue30
        |> Decimal.new()
        |> Decimal.div(Decimal.new(30))
        |> Decimal.mult(Decimal.new(365))
        |> Decimal.div(value)

      {:ok,
       %__MODULE__.Summary{
         id: pool.address,
         apr: apr,
         revenue: revenue,
         revenue1: sum_revenue(revenue, 1),
         revenue7: sum_revenue(revenue, 7),
         revenue30: revenue30
       }}
    end
  end

  defmemo get_revenue(%__MODULE__{address: address, revenue_denom: denom}, days),
    expires_in: 60 * 60 * 1000 do
    Rujira.Repo.all(
      from(t in Rujira.Bank.Transfer,
        select: %{
          timestamp: fragment("date_trunc('day', ?)", t.timestamp),
          amount: fragment("SUM(?)::bigint", t.amount)
        },
        group_by: fragment("date_trunc('day', ?)", t.timestamp),
        where:
          t.denom == ^denom and t.recipient == ^address and
            t.timestamp > ^DateTime.add(DateTime.utc_now(), -days, :day)
      )
    )
  end

  defp sum_revenue(list, limit) do
    Enum.reduce(list, 0, fn %{timestamp: ts, amount: v}, acc ->
      if DateTime.diff(DateTime.utc_now(), DateTime.from_naive!(ts, "Etc/UTC"), :day) < limit do
        acc + v
      else
        acc
      end
    end)
  end
end
