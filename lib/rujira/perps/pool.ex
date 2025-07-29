defmodule Rujira.Perps.Pool do
  @moduledoc """
  Rujira Perps Pool.
  """

  defmodule Stats do
    @moduledoc false
    defstruct [
      :sharpe_ratio,
      :lp_apr,
      :xlp_apr,
      :risk
    ]

    @type t :: %__MODULE__{
            sharpe_ratio: non_neg_integer(),
            lp_apr: non_neg_integer(),
            xlp_apr: non_neg_integer(),
            risk: non_neg_integer()
          }
  end

  defstruct [
    :id,
    :address,
    :name,
    :base_denom,
    :quote_denom,
    :liquidity,
    :stats
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          address: String.t(),
          name: String.t(),
          base_denom: String.t(),
          quote_denom: String.t(),
          stats: Stats.t()
        }

  def from_query(address, %{
        "base" => base,
        "liquidity" => liquidity,
        "market_id" => market_id,
        "collateral" => %{"native" => %{"denom" => quote_denom}}
      }) do
    with {:ok, liquidity} <- parse_liquidity(liquidity) do
      {:ok,
       %__MODULE__{
         id: address,
         address: address,
         name: market_id,
         base_denom: base,
         quote_denom: quote_denom,
         liquidity: liquidity
       }
       |> add_stats()}
    end
  end

  def add_stats(pool) do
    %__MODULE__{
      pool
      | stats: %__MODULE__.Stats{
          sharpe_ratio: 0,
          lp_apr: 0,
          xlp_apr: 0,
          risk: 0
        }
    }
  end

  defp parse_liquidity(%{"unlocked" => unlocked, "locked" => locked}) do
    with {unlocked, ""} <- Decimal.parse(unlocked),
         {locked, ""} <- Decimal.parse(locked) do
      {:ok,
       %{
         total: normalize(Decimal.add(unlocked, locked)),
         unlocked: normalize(unlocked),
         locked: normalize(locked)
       }}
    end
  end

  # query store liquidity as decimal
  # need to normalize and add the 8 decimals places according to the api standard
  defp normalize(decimal),
    do: Decimal.round(decimal) |> Decimal.mult(100_000_000) |> Decimal.to_integer()
end
