defmodule RujiraWeb.Schema.BowTypes do
  alias Rujira.Assets
  alias Rujira.Bow.Xyk
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:bow_pool) do
    field :address, non_null(:string)
    field :config, non_null(:bow_config)
    field :state, non_null(:bow_state)

    field :summary, :bow_summary do
      resolve(&RujiraWeb.Resolvers.Bow.summary/3)
    end

    connection field :trades, node_type: :fin_trade, non_null: true do
      resolve(&RujiraWeb.Resolvers.Bow.trades/3)
    end
  end

  union :bow_config do
    types([:bow_config_xyk])

    resolve_type(fn
      %Xyk.Config{}, _ -> :bow_config_xyk
    end)
  end

  object :bow_config_xyk do
    field :x, non_null(:asset) do
      resolve(fn %{x: x}, _, _ ->
        Assets.from_denom(x)
      end)
    end

    field :y, non_null(:asset) do
      resolve(fn %{y: y}, _, _ ->
        Assets.from_denom(y)
      end)
    end

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
    field :shares, non_null(:balance)
  end

  union :bow_summary do
    types([:bow_summary_xyk])

    resolve_type(fn
      %Xyk.Summary{}, _ -> :bow_summary_xyk
    end)
  end

  object :bow_summary_xyk do
    field :spread, non_null(:bigint)
    field :depth_bid, non_null(:bigint)
    field :depth_ask, non_null(:bigint)
    field :volume, non_null(:bigint)
    field :utilization, non_null(:bigint)
  end

  node object(:bow_account) do
    field :account, non_null(:address)
    field :pool, non_null(:bow_pool)

    field :shares, non_null(:balance) do
      resolve(fn %{shares: shares, pool: %{config: %{share_denom: share_denom}}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(share_denom) do
          {:ok, %{amount: shares, asset: asset}}
        end
      end)
    end

    field :value, non_null(list_of(non_null(:balance))) do
      resolve(fn %{value: value}, _, _ ->
        Rujira.Enum.reduce_while_ok(value, [], fn %{amount: amount, denom: denom} ->
          with {:ok, asset} <- Assets.from_denom(denom) do
            {:ok, %{amount: amount, asset: asset}}
          end
        end)
      end)
    end
  end
end
