defmodule RujiraWeb.Schema.Calc.Common.PriceStrategyTypes do
  @moduledoc """
  Defines GraphQL types for price strategy data in Calc Protocol.

  This module contains type definitions for different pricing strategies including
  fixed prices and offset-based pricing with directional controls.
  """
  use Absinthe.Schema.Notation

  union :calc_price_strategy_type do
    types([:calc_price_strategy_fixed, :calc_price_strategy_offset])

    resolve_type(fn
      %Rujira.Calc.Common.PriceStrategy.Fixed{}, _ -> :calc_price_strategy_fixed
      %Rujira.Calc.Common.PriceStrategy.Offset{}, _ -> :calc_price_strategy_offset
    end)
  end

  object :calc_price_strategy_fixed do
    field :price, non_null(:bigint)
  end


  object :calc_price_strategy_offset do
    field :side, non_null(:calc_side)
    field :direction, non_null(:calc_price_strategy_offset_direction)
    field :offset, non_null(:calc_offset_type)
    field :tolerance, :bigint
  end

  union :calc_offset_type do
    types([:calc_offset_exact, :calc_offset_percent])

    resolve_type(fn
      %{"exact" => _}, _ -> :calc_offset_exact
      %{"percent" => _}, _ -> :calc_offset_percent
    end)
  end

  object :calc_offset_exact do
    field :exact, non_null(:float)
  end

  object :calc_offset_percent do
    field :percent, non_null(:bigint)
  end

  enum :calc_side do
    value(:base)
    value(:quote)
  end

  enum :calc_price_strategy_offset_direction do
    value(:above)
    value(:below)
  end
end
