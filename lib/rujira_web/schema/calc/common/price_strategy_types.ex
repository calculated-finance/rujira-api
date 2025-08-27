defmodule RujiraWeb.Schema.Calc.Common.PriceStrategyTypes do
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
    field :offset, non_null(:bigint)
    field :tolerance, :bigint
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
