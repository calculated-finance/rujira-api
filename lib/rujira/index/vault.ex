defmodule Rujira.Index.Vault do
  @moduledoc """
  Defines the structure and operations for index vaults.
  """
  alias Rujira.Index.Fixed
  alias Rujira.Index.Nav

  use Memoize

  defmodule Config do
    @moduledoc """
    Configuration settings for an index vault.
    """
    @type t :: %__MODULE__{
            quote_denom: String.t(),
            fee_collector: String.t()
          }
    defstruct [:quote_denom, :fee_collector]
  end

  defmodule Allocation do
    @moduledoc """
    Represents asset allocation within a vault.
    """
    @type t :: %__MODULE__{
            denom: String.t(),
            target_weight: non_neg_integer(),
            current_weight: Decimal.t(),
            value: non_neg_integer(),
            balance: non_neg_integer(),
            price: Decimal.t()
          }

    defstruct [:denom, :target_weight, :current_weight, :value, :balance, :price]
  end

  defmodule Status do
    @moduledoc """
    Current status and metrics of a vault.
    """
    alias Rujira.Index.Fixed
    alias Rujira.Index.Nav

    @type t :: %__MODULE__{
            nav: Decimal.t(),
            total_shares: non_neg_integer(),
            total_value: non_neg_integer(),
            allocations: list(Allocation.t()),
            nav_change: Decimal.t() | nil,
            nav_quote: Decimal.t() | nil
          }

    defstruct [:nav, :total_shares, :total_value, :allocations, :nav_change, :nav_quote]

    def from_query(%{
          "nav" => nav_str,
          "shares" => shares_str,
          "total_value" => total_value_str,
          "allocation" => raw_allocs
        }) do
      with {nav, ""} <- Decimal.parse(nav_str),
           {shares, ""} <- Integer.parse(shares_str),
           {total_value, ""} <- Integer.parse(total_value_str),
           {:ok, allocations} <- Nav.parse_allocations(raw_allocs) do
        allocations = Nav.add_current_weights(allocations)

        {:ok,
         %__MODULE__{
           nav: nav,
           total_shares: shares,
           total_value: total_value,
           allocations: allocations
         }}
      else
        error -> error
      end
    end

    def from_query(%{"total_shares" => total_shares_str, "allocation" => raw_allocations}) do
      with {total_shares, ""} <- Integer.parse(total_shares_str),
           {:ok, allocations} <- Fixed.parse_allocations(raw_allocations, total_shares) do
        total_value = Enum.reduce(allocations, 0, &(&2 + &1.value))

        nav =
          if total_shares == 0,
            do: Decimal.new(1),
            else: Decimal.div(Decimal.new(total_value), total_shares)

        {:ok,
         %__MODULE__{
           total_shares: total_shares,
           total_value: total_value,
           allocations: Fixed.assign_current_weights(allocations),
           nav: nav
         }}
      else
        error -> error
      end
    end
  end

  defmodule Fees do
    @moduledoc """
    Fee structure and calculations for vault operations.
    """
    defmodule Rates do
      @moduledoc """
      Fee rates applied to vault operations.
      """
      @type t :: %__MODULE__{
              management: Decimal.t(),
              performance: Decimal.t(),
              transaction: Decimal.t()
            }

      defstruct [:management, :performance, :transaction]

      def from_query(%{
            "management" => management,
            "performance" => performance,
            "transaction" => transaction
          }) do
        {:ok,
         %__MODULE__{
           management: parse_rate(management),
           performance: parse_rate(performance),
           transaction: parse_rate(transaction)
         }}
      end

      defp parse_rate(nil), do: Decimal.new(0)

      defp parse_rate(value) do
        case Decimal.parse(value) do
          {decimal, ""} -> decimal
          _ -> Decimal.new(0)
        end
      end
    end

    @type t :: %__MODULE__{
            last_accrual_time: String.t(),
            high_water_mark: Decimal.t(),
            rates: Rates.t()
          }

    defstruct [:last_accrual_time, :high_water_mark, :rates]

    def from_query(%{
          "last_accrual_time" => last_accrual_time,
          "high_water_mark" => high_water_mark,
          "rates" => rates
        }) do
      with {high_water_mark, ""} <- Decimal.parse(high_water_mark),
           {:ok, rates} <- Rates.from_query(rates),
           {last_accrual_time, ""} <- Integer.parse(last_accrual_time),
           {:ok, last_accrual_time} <- DateTime.from_unix(last_accrual_time, :nanosecond) do
        {:ok,
         %__MODULE__{
           last_accrual_time: last_accrual_time,
           high_water_mark: high_water_mark,
           rates: rates
         }}
      else
        error -> error
      end
    end
  end

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          module: Nav | Fixed,
          config: Config.t(),
          status: Status.t() | :not_loaded,
          fees: Fees.t() | :not_loaded,
          share_denom: String.t(),
          entry_adapter: String.t() | nil
        }

  defstruct [
    :id,
    :address,
    :module,
    :config,
    :status,
    :fees,
    :share_denom,
    :entry_adapter
  ]

  defmemo status(res), expires_in: 60_000 do
    Status.from_query(res)
  end
end
