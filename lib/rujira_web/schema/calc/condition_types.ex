defmodule RujiraWeb.Schema.Calc.ConditionTypes do
  @moduledoc """
  Defines GraphQL types for Calc Protocol data in the Rujira API.

  This module contains the type definitions and field resolvers for Calc Protocol
  GraphQL objects, including conditions, and related data structures.
  """
  use Absinthe.Schema.Notation
  alias Rujira.Calc.Condition

  import_types(RujiraWeb.Schema.Calc.Condition.ScheduleTypes)

  object :calc_condition do
    field :condition, non_null(:calc_condition_type)
    field :index, non_null(:integer)
    field :on_success, :integer
    field :on_failure, :integer
  end

  union :calc_condition_type do
    types([
      :calc_condition_blocks_completed,
      :calc_condition_can_swap,
      :calc_condition_schedule,
      :calc_condition_timestamp_elapsed
    ])

    resolve_type(fn
      %Condition.BlocksCompleted{}, _ -> :calc_condition_blocks_completed
      %Condition.CanSwap{}, _ -> :calc_condition_can_swap
      %Condition.Schedule{}, _ -> :calc_condition_schedule
      %Condition.TimestampElapsed{}, _ -> :calc_condition_timestamp_elapsed
    end)
  end

  object :calc_condition_blocks_completed do
    field :test, :string
  end

  object :calc_condition_can_swap do
    field :test, :string
  end

  object :calc_condition_timestamp_elapsed do
    field :test, :string
  end
end
