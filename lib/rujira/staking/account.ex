defmodule Rujira.Staking.Account do
  @moduledoc """
  Parses staking account data from the blockchain into an Account struct.
  """
  alias Rujira.Staking.Pool

  defstruct [
    :id,
    :pool,
    :account,
    :bonded,
    :pending_revenue
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          pool: Pool.t(),
          account: String.t(),
          bonded: integer(),
          pending_revenue: integer()
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
         id: "#{pool.id}/#{address}",
         pool: pool,
         account: address,
         bonded: bonded,
         pending_revenue: pending_revenue
       }}
    else
      _ -> {:error, :parse_error}
    end
  end

  def default(pool, account) do
    {:ok,
     %__MODULE__{
       id: "#{pool.id}/#{account}",
       pool: pool,
       account: account,
       bonded: 0,
       pending_revenue: 0
     }}
  end
end
