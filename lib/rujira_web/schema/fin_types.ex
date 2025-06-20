defmodule RujiraWeb.Schema.FinTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias Rujira.Contracts
  alias Rujira.Fin
  alias Rujira.Assets

  @desc "A fin_pair represents informations about a specific rujira-fin contract"
  node object(:fin_pair) do
    field :address, non_null(:address)

    field :contract, non_null(:contract_info) do
      resolve(fn %{address: address}, _, _ ->
        Contracts.info(address)
      end)
    end

    field :asset_base, non_null(:asset) do
      resolve(fn %{token_base: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :asset_quote, non_null(:asset) do
      resolve(fn %{token_quote: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :oracle_base, :thorchain_oracle do
      resolve(fn
        %{oracle_base: nil}, _, _ ->
          {:ok, nil}

        %{oracle_base: asset}, _, _ ->
          RujiraWeb.Resolvers.Thorchain.oracle(asset)
      end)
    end

    field :oracle_quote, :thorchain_oracle do
      resolve(fn
        %{oracle_quote: nil}, _, _ ->
          {:ok, nil}

        %{oracle_quote: asset}, _, _ ->
          RujiraWeb.Resolvers.Thorchain.oracle(asset)
      end)
    end

    field :tick, non_null(:bigint)
    field :fee_taker, non_null(:bigint)
    field :fee_maker, non_null(:bigint)
    field :fee_address, non_null(:address)
    field :book, non_null(:fin_book), resolve: &RujiraWeb.Resolvers.Fin.book/3
    field :summary, :fin_summary, resolve: &RujiraWeb.Resolvers.Fin.summary/3

    connection field :candles, node_type: :fin_candle, non_null: true do
      arg(:resolution, non_null(:string))
      resolve(&RujiraWeb.Resolvers.Fin.candles/3)
    end

    connection field :trades, node_type: :fin_trade, non_null: true do
      resolve(&RujiraWeb.Resolvers.Fin.trades/3)
    end
  end

  connection(node_type: :fin_trade)
  connection(node_type: :fin_candle)
  connection(node_type: :fin_order)
  connection(node_type: :fin_account_action)

  @desc "Orderbook of a specific Fin pair"
  node object(:fin_book) do
    field :asks, non_null(list_of(non_null(:fin_book_entry)))
    field :center, :bigint
    field :spread, :bigint
    field :bids, non_null(list_of(non_null(:fin_book_entry)))

    field :pair, non_null(:fin_pair) do
      resolve(&RujiraWeb.Resolvers.Fin.book_pair/3)
    end
  end

  @desc "single entry of an orderbook"
  object :fin_book_entry do
    field :price, non_null(:bigint)
    field :total, non_null(:bigint)
    field :side, non_null(:string)
    @desc "Value of the entry, calculated as total * price or total / price based on side."
    field :value, non_null(:bigint)
  end

  @desc "Collections of data of an account across all the fin pairs"
  object :fin_account do
    connection field :orders, node_type: :fin_order do
      resolve(&RujiraWeb.Resolvers.Fin.orders/3)
    end

    connection field :history, node_type: :fin_account_action do
      resolve(&RujiraWeb.Resolvers.Fin.history/3)
    end
  end

  @desc "Single order of an account on a fin pair"
  node object(:fin_order) do
    field :pair, non_null(:fin_pair) do
      resolve(fn %{pair: pair}, _, _ ->
        Fin.get_pair(pair)
      end)
    end

    field :owner, non_null(:address)
    field :side, non_null(:string)
    field :rate, non_null(:bigint)
    field :updated_at, non_null(:timestamp)
    @desc "The amount of asset offered at updated_at"
    field :offer, non_null(:bigint)
    @desc "The value of the offer in the ask asset"
    field :offer_value, non_null(:bigint)
    @desc "The remaining amount of offer asset"
    field :remaining, non_null(:bigint)
    @desc "The value of the remaining offer in the ask asset"
    field :remaining_value, non_null(:bigint)
    @desc "The amount of ask asset available for withdrawal"
    field :filled, non_null(:bigint)
    @desc "The value of ask asset available for withdrawal in the offer asset"
    field :filled_value, non_null(:bigint)
    field :filled_fee, non_null(:bigint)
    field :type, non_null(:string)
    field :deviation, :bigint
    @desc "The value of the order in USD as remaining value + filled value"
    field :value_usd, non_null(:bigint)
  end

  @desc "Single trade executed by on a fin pair"
  node object(:fin_trade) do
    field :height, non_null(:bigint)
    field :tx_idx, non_null(:bigint)
    field :idx, non_null(:bigint)
    field :contract, non_null(:address)
    field :txhash, non_null(:string)
    field :quote_amount, non_null(:bigint)
    field :base_amount, non_null(:bigint)

    field :price, non_null(:bigint) do
      resolve(fn %{rate: rate}, _, _ -> {:ok, rate} end)
    end

    field :type, non_null(:string)
    field :protocol, non_null(:string)
    field :timestamp, non_null(:timestamp)

    field :asset_base, non_null(:asset) do
      resolve(fn %{base_token: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :asset_quote, non_null(:asset) do
      resolve(fn %{quote_token: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end
  end

  # TODO Actual polymorfic structure to hanlde orders + swaps
  @desc "Single action executed by an account on a fin pair"
  object :fin_account_action do
    field :type, :string
    field :height, :bigint
    field :tx_idx, :bigint
    field :idx, :bigint
    field :contract, :address
    field :txhash, :string
    field :quote_amount, :bigint
    field :base_amount, :bigint
    field :price, :bigint
    field :protocol, :string
    field :timestamp, :timestamp

    field :asset_base, :asset do
      resolve(fn %{base_token: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :asset_quote, :asset do
      resolve(fn %{quote_token: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end
  end

  @desc "Summary of the last trading data for a specific pair, including high, low, change, and volume."
  node object(:fin_pair_summary) do
    field :last, non_null(:bigint)
    field :last_usd, non_null(:bigint)
    field :high, non_null(:bigint)
    field :low, non_null(:bigint)
    field :change, non_null(:bigint)
    field :volume, non_null(:layer_1_balance)
  end

  object(:fin_summary) do
    field :last, non_null(:bigint)
    field :last_usd, non_null(:bigint)
    field :high, non_null(:bigint)
    field :low, non_null(:bigint)
    field :change, non_null(:bigint)
    field :volume, non_null(:layer_1_balance)
  end

  @desc "Represents a candlestick chart data point for a specific time period, including high, low, open, close, volume, and timestamp."
  node object(:fin_candle) do
    field :resolution, non_null(:string)
    field :high, non_null(:bigint)
    field :low, non_null(:bigint)
    field :open, non_null(:bigint)
    field :close, non_null(:bigint)
    field :volume, non_null(:bigint)
    field :bin, non_null(:timestamp)
  end

  object :fin_subscriptions do
    @desc """
    Triggered any time an order is created, increased or decreased.
    One subscription for all orders for a given contract & owner.
    """
    field :fin_order_updated, :node_edge do
      arg(:contract, :address, deprecate: "contract is read from the observed event")
      arg(:owner, non_null(:address))

      config(fn %{owner: owner}, _ ->
        {:ok, topic: owner}
      end)

      resolve(&RujiraWeb.Resolvers.Fin.order_edge/3)
    end

    @desc """
    Triggered when a order is filled.
    One subscription per order.
    """
    field :fin_order_filled, :node_edge do
      arg(:contract, non_null(:address))
      arg(:side, non_null(:string))
      arg(:price, non_null(:string))
      arg(:owner, non_null(:address))

      config(fn %{contract: contract, side: side, price: price}, _ ->
        {:ok, topic: "#{contract}/#{side}/#{price}"}
      end)

      resolve(&RujiraWeb.Resolvers.Fin.order_edge/3)
    end
  end
end
