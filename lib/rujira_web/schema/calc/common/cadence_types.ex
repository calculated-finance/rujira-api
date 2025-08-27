defmodule RujiraWeb.Schema.Calc.Common.CadenceTypes do
  @moduledoc """
  Defines GraphQL types for cadence scheduling data in Calc Protocol.

  This module contains type definitions for different cadence types including
  block-based, time-based, cron expressions, and limit order cadences.
  """
  use Absinthe.Schema.Notation

  import_types(RujiraWeb.Schema.Calc.Common.PriceStrategyTypes)

  union :calc_cadence_type do
    types([
      :calc_cadence_blocks,
      :calc_cadence_time,
      :calc_cadence_cron,
      :calc_cadence_limit_order
    ])

    resolve_type(fn
      %Rujira.Calc.Common.Cadence.Blocks{}, _ -> :calc_cadence_blocks
      %Rujira.Calc.Common.Cadence.Time{}, _ -> :calc_cadence_time
      %Rujira.Calc.Common.Cadence.Cron{}, _ -> :calc_cadence_cron
      %Rujira.Calc.Common.Cadence.LimitOrder{}, _ -> :calc_cadence_limit_order
    end)
  end

  object :calc_cadence_blocks do
    field :interval, non_null(:integer)
    field :previous, :integer
  end

  object :calc_cadence_time do
    field :duration, non_null(:integer)
    field :previous, :integer
  end

  object :calc_cadence_cron do
    field :expr, non_null(:string)
    field :previous, :integer
  end

  object :calc_cadence_limit_order do
    field :pair_address, non_null(:address)
    field :side, non_null(:calc_side)
    field :strategy, non_null(:calc_price_strategy_type)
    field :previous, :integer
  end
end
