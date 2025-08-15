defmodule Rujira.Staking.Pool do
  @moduledoc """
  Parses and manages staking pool data from the blockchain into a Pool struct.

  Handles pool configuration, status tracking, and revenue calculations.
  """

  alias Rujira.Analytics
  alias Rujira.Assets
  alias Rujira.Deployments.Target
  use Memoize

  defmodule Summary do
    @moduledoc """
    Defines the structure for a staking pool summary.
    """
    defstruct [
      :id,
      :apr,
      :apy,
      :revenue7
    ]

    @type t :: %__MODULE__{
            id: String.t(),
            apr: map(),
            apy: map(),
            revenue7: integer()
          }
  end

  defmodule Status do
    @moduledoc """
    Defines the structure for a staking pool status.
    """
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
    :receipt_denom,
    :revenue_denom,
    :revenue_converter,
    :status,
    :deployment_status
  ]

  @type revenue_converter_t :: {String.t(), binary(), integer()}

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          bond_denom: String.t(),
          receipt_denom: String.t(),
          revenue_denom: String.t(),
          revenue_converter: revenue_converter_t(),
          status: :not_loaded | Status.t(),
          deployment_status: Target.status()
        }

  @spec from_config(String.t(), map()) :: {:ok, __MODULE__.t()}
  def from_config(address, %{
        "bond_denom" => bond_denom,
        "revenue_denom" => revenue_denom,
        "revenue_converter" => [contract, msg, min]
      }) do
    with {min, ""} <- Integer.parse(min) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         bond_denom: bond_denom,
         receipt_denom: "x/staking-#{bond_denom}",
         revenue_denom: revenue_denom,
         revenue_converter: [contract, msg, min],
         status: :not_loaded,
         deployment_status: :live
       }}
    end
  end

  def summary(%__MODULE__{} = pool) do
    case Analytics.Staking.summary(pool.address) do
      {:ok, %{apr: apr, apy: apy, revenue: revenue}} ->
        {:ok,
         %__MODULE__.Summary{
           id: pool.address,
           apr: %{status: :available, value: apr},
           apy: %{status: :available, value: apy},
           revenue7: revenue
         }}

      {:ok, nil} ->
        {:ok,
         %__MODULE__.Summary{
           id: pool.address,
           apr: %{status: :soon},
           apy: %{status: :soon},
           revenue7: Decimal.new(0)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_target(%Target{
        address: address,
        config: %{
          "bond_denom" => bond_denom,
          "revenue_converter" => %{"contract" => contract, "min" => min, "msg" => msg},
          "revenue_denom" => revenue_denom
        },
        status: status
      }) do
    with {:ok, pool} <-
           from_config(address, %{
             "bond_denom" => bond_denom,
             "revenue_converter" => [contract, Base.encode64(msg), min],
             "revenue_denom" => revenue_denom
           }) do
      {:ok, %{pool | deployment_status: status}}
    end
  end

  def init_msg(%{
        "bond_denom" => bond_denom,
        "revenue_converter" => %{"contract" => contract, "msg" => msg, "min" => min},
        "revenue_denom" => revenue_denom
      }) do
    {:ok, asset} = Assets.from_denom(bond_denom)

    %{
      bond_denom: bond_denom,
      revenue_denom: revenue_denom,
      receipt_token_metadata: %{
        description:
          "Transferable shares issued when staking #{asset.ticker} on Rujira via the Auto-Compounding interface",
        display: "x/staking-#{bond_denom}",
        name: "Auto-Compounding #{asset.ticker}",
        symbol: "s#{asset.ticker}"
      },
      revenue_converter: [contract, Base.encode64(msg), min]
    }
  end

  def migrate_msg(_from, _to, _), do: %{}

  def init_label(_, %{"bond_denom" => x}), do: "rujira-staking:#{x}"
end
