defmodule RujiraWeb.Schema.FinTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "A fin_pair represents informations about a specific rujira-fin contract"
  node object(:fin_pair) do
    field :address, non_null(:address)

    field :token_base, non_null(:denom) do
      resolve(fn %{token_base: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :token_quote, non_null(:denom) do
      resolve(fn %{token_quote: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :price_precision, non_null(:bigint)
    field :decimal_delta, non_null(:bigint)
    field :fee_taker, non_null(:bigint)
    field :fee_maker, non_null(:bigint)
    field :book, non_null(:book)
    field :summary, :string #TODO type
    field :candles, :string #TODO type
    field :history, list_of(:trade)
  end

  @desc "Orderbook of a specific Fin pair"
  object :book do
    field :asks, list_of(:book_price)
    field :bids, list_of(:book_price)
  end

  @desc "single entry of an orderbook"
  object :book_price do
    field :price, :bigint
    field :total, :bigint
    field :type, :string
  end

  @desc "Collections of data of an account across all the fin pairs"
  object :fin_account do
    field :orders, list_of(:order)
    field :history, list_of(:fin_account_action)
  end

  @desc "Single order of an account on a fin pair"
  object :order do
    field :pair, :address
    field :id, :bigint
    field :owner, :address
    field :price, :bigint

    field :offer_token, :denom do
      resolve(fn %{offer_token: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :original_offer_amount, :bigint
    field :remaining_offer_amount, :bigint
    field :filled_amount, :bigint
    field :created_at, :timestamp
  end

  @desc "Single trade executed by on a fin pair"
  object :trade do
    field :height, :bigint
    field :tx_idx, :bigint
    field :idx, :bigint
    field :contract, :address
    field :txhash, :string
    field :quote_amount, :bigint
    field :base_amount, :bigint
    field :price, :bigint
    field :type, :string
    field :protocol, :string
    field :timestamp, :timestamp

    field :base_token, :denom do
      resolve(fn %{base_token: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :quote_token, :denom do
      resolve(fn %{quote_token: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
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
    field :base_token, :denom do
      resolve(fn %{base_token: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end

    field :quote_token, :denom do
      resolve(fn %{quote_token: denom}, x, y ->
        RujiraWeb.Resolvers.Token.denom(%{denom: denom}, x, y)
      end)
    end
  end
end
