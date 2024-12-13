defmodule Rujira.Merge.Account do
  alias Rujira.Merge.Pool
  @precision 1_000_000_000_000

  defstruct [
    :pool,
    :account,
    :merged,
    :shares,
    :size,
    :rate
  ]

  @type t :: %__MODULE__{
          pool: Pooo.t(),
          account: String.t(),
          merged: integer(),
          shares: integer(),
          size: integer(),
          rate: integer()
        }

  @spec from_query(Pool.t(), map()) :: {:ok, __MODULE__.t()} | :error
  def from_query(
        %Pool{} = pool,
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
         pool: pool,
         account: address,
         merged: merged,
         shares: shares,
         size: size,
         rate: trunc(div(merged * @precision, size))
       }}
    else
      _ -> :error
    end
  end
end
