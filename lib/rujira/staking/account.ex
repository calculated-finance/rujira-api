defmodule Rujira.Staking.Account do
  @moduledoc """
  Parses staking account data from the blockchain into an Account struct.
  """
  alias Rujira.Chains.Thor
  alias Rujira.Staking
  alias Rujira.Staking.Pool

  defstruct [
    :id,
    :pool,
    :account,
    :bonded,
    :pending_revenue,
    :liquid_shares,
    :liquid_size
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          pool: Pool.t(),
          account: String.t(),
          bonded: integer(),
          liquid_shares: non_neg_integer(),
          liquid_size: non_neg_integer(),
          pending_revenue: non_neg_integer()
        }

  @spec from_query(Pool.t(), map()) :: {:ok, __MODULE__.t()} | {:error, :parse_error}
  def from_query(
        %Pool{} = pool,
        %{
          "addr" => address,
          "bonded" => bonded,
          "pending_revenue" => pending_revenue
        }
      ) do
    with {bonded, ""} <- Integer.parse(bonded),
         {pending_revenue, ""} <- Integer.parse(pending_revenue) do
      {:ok,
       %__MODULE__{
         id: "#{pool.address}/#{address}",
         pool: pool,
         account: address,
         bonded: bonded,
         pending_revenue: pending_revenue + unallocated_revenue(pool, bonded)
       }}
    else
      _ -> {:error, :parse_error}
    end
  end

  def load_balance(
        %Pool{} = pool,
        %__MODULE__{account: address} = account
      ) do
    with {:ok,
          %{
            receipt_denom: receipt_denom,
            status: %{
              liquid_bond_size: liquid_bond_size,
              liquid_bond_shares: liquid_bond_shares
            }
          }} <- Staking.load_pool(pool),
         {:ok, balance} <- Thor.balance_of(address, receipt_denom),
         {liquid_shares, ""} <- Integer.parse(balance.amount) do
      {:ok,
       %{
         account
         | liquid_shares: liquid_shares,
           liquid_size:
             if(liquid_bond_shares > 0,
               do: floor(liquid_shares * liquid_bond_size / liquid_bond_shares),
               else: 0
             )
       }}
    else
      {:error, %GRPC.RPCError{}} ->
        {:ok, %{account | liquid_shares: 0, liquid_size: 0}}

      other ->
        other
    end
  end

  def default(pool, account) do
    %__MODULE__{
      id: "#{pool.address}/#{account}",
      pool: pool,
      account: account,
      bonded: 0,
      pending_revenue: 0,
      liquid_shares: 0,
      liquid_size: 0
    }
  end

  # Contract current doesn't allocate global pending revnue to Account balance on Query,
  # which is does on a withdrawal.
  # Simulate distribution here: https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L183
  # https://gitlab.com/thorchain/rujira/-/blob/main/contracts/rujira-staking/src/state.rs?ref_type=heads#L135-139
  defp unallocated_revenue(_, 0), do: 0

  defp unallocated_revenue(
         %{
           status: %{
             account_bond: account_bond,
             liquid_bond_size: liquid_bond_size,
             pending_revenue: global_pending_revenue
           }
         },
         bonded
       ) do
    Integer.floor_div(
      Integer.floor_div(
        account_bond * global_pending_revenue,
        account_bond + liquid_bond_size
      ) * bonded,
      account_bond
    )
  end

  defp unallocated_revenue(%{status: :not_loaded} = pool, bonded) do
    case Staking.load_pool(pool) do
      {:ok, pool} -> unallocated_revenue(pool, bonded)
      _ -> 0
    end
  end
end
