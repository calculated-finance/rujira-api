defmodule Rujira.Staking.Account do
  alias Rujira.Staking.Pool

  defstruct [
    :pool,
    :account,
    :bonded,
    :pending_revenue
  ]

  @type t :: %__MODULE__{
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
         pool: pool,
         account: address,
         bonded: bonded,
         pending_revenue: pending_revenue
       }}
    else
      _ -> {:error, :parse_error}
    end
  end
end
