defmodule RujiraWeb.Schema.Calc.Condition.ScheduleTypes do
  use Absinthe.Schema.Notation

  import_types(RujiraWeb.Schema.Calc.Common.CadenceTypes)

  object :calc_condition_schedule do
    field :cadence, non_null(:calc_cadence_type)
    field :next, :calc_cadence_type
    field :execution_rebate, list_of(non_null(:balance))
    field :executors, list_of(non_null(:address))
    field :jitter, :integer
  end
end
