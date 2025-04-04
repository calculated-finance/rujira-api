defmodule Rujira.Merge.Account do
  alias Rujira.Merge.Pool

  defstruct [
    :id,
    :pool,
    :account,
    :merged,
    :shares,
    :size,
    :rate
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          pool: Pool.t(),
          account: String.t(),
          merged: integer(),
          shares: integer(),
          size: integer(),
          rate: Decimal.t()
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
      rate =
        if size == 0 do
          0
        else
          merged
          |> Decimal.new()
          |> Decimal.div(Decimal.new(size))
        end

      {:ok,
       %__MODULE__{
         id: "#{pool.id}/#{address}",
         pool: pool,
         account: address,
         merged: merged,
         shares: shares,
         size: size,
         rate: rate
       }}
    else
      _ -> :error
    end
  end
end
