defmodule Rujira.Leagues.Account do
  @moduledoc """
  Defines the structure for league participant accounts and their statistics.
  """
  @type t :: %__MODULE__{
          id: String.t(),
          league: String.t(),
          season: non_neg_integer(),
          address: String.t(),
          points: non_neg_integer(),
          total_tx: non_neg_integer(),
          rank: non_neg_integer(),
          rank_previous: non_neg_integer() | nil,
          badges: list(String.t()),
          transactions: list(map())
        }

  defstruct [
    :id,
    :league,
    :season,
    :address,
    :points,
    :total_tx,
    :rank,
    :rank_previous,
    :badges,
    :transactions
  ]
end
