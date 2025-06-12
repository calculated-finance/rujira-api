defmodule Rujira.Index.Vault do
  alias Rujira.Index.Nav
  alias Rujira.Index.Fixed

  use Memoize

  defmodule Config do
    @type t :: %__MODULE__{
            quote_denom: String.t(),
            fee_collector: String.t()
          }
    defstruct [:quote_denom, :fee_collector]
  end

  defmodule Allocation do
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
    alias Rujira.Index.Fixed
    alias Rujira.Index.Nav

    @type t :: %__MODULE__{
            nav: Decimal.t(),
            total_shares: non_neg_integer(),
            total_value: non_neg_integer(),
            allocations: list(Allocation.t()),
            nav_change: Decimal.t() | nil
          }

    defstruct [:nav, :total_shares, :total_value, :allocations, :nav_change]

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

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          module: Nav | Fixed,
          config: Config.t(),
          status: Status.t() | :not_loaded,
          share_denom: String.t(),
          entry_adapter: String.t() | nil
        }

  defstruct [
    :id,
    :address,
    :module,
    :config,
    :status,
    :share_denom,
    :entry_adapter
  ]

  defmemo status(res), expires_in: 60_000 do
    Status.from_query(res)
  end
end
