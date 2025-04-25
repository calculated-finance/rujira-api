defmodule RujiraWeb.Schema.BowTypes do
  alias Rujira.Bow.Xyk
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:bow_pool) do
    field :address, non_null(:string)
    field :config, non_null(:bow_config)
    field :state, non_null(:bow_state)
  end

  union :bow_config do
    types([:bow_config_xyk])

    resolve_type(fn
      %Xyk.Config{}, _ -> :bow_config_xyk
    end)
  end

  object :bow_config_xyk do
    field :x, non_null(:string)
    field :y, non_null(:string)
    field :step, non_null(:bigint)
    field :min_quote, non_null(:bigint)
    field :fee, non_null(:bigint)
  end

  union :bow_state do
    types([:bow_state_xyk])

    resolve_type(fn
      %Xyk.State{}, _ -> :bow_state_xyk
    end)
  end

  object :bow_state_xyk do
    field :x, non_null(:bigint)
    field :y, non_null(:bigint)
    field :k, non_null(:bigint)
    field :shares, non_null(:bigint)
  end
end
