defmodule Rujira.Merge.Account do
  alias Rujira.Merge.Pool

  defstruct [
    :pool,
    :account,
    :merged,
    :shares,
    :size
  ]

  @type t :: %__MODULE__{
          pool: {Pool.t(), String.t()},
          account: String.t(),
          merged: integer(),
          shares: integer(),
          size: integer()
        }

  @spec from_query(Pool.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_query(
        %Pool{address: pool_address} = pool,
        %{
          "addr" => address,
          "merged" => merged,
          "shares" => shares,
          "size" => size
        }
      ) do
    with {merged, ""} <- Integer.parse(merged),
         {shares, ""} <- Integer.parse(shares),
         {size, ""} <- Integer.parse(size) do
      {:ok,
       %__MODULE__{
         pool: {pool, pool_address},
         account: address,
         merged: merged,
         shares: shares,
         size: size
       }}
    else
      _ -> :error
    end
  end
end
