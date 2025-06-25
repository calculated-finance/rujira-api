defmodule RujiraWeb.Schema.TokenTypes do
  @moduledoc """
  Defines GraphQL types for Token data in the Rujira API.

  This module contains the type definitions and field resolvers for Token
  GraphQL objects, including asset information and token metadata.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers.Token

  node object(:asset) do
    field :asset, non_null(:asset_string), resolve: &Token.string/3
    field :type, non_null(:asset_type)
    field :chain, non_null(:chain), resolve: &Token.chain/3
    field :metadata, non_null(:metadata), resolve: &Token.metadata/3

    field :price, :price do
      resolve(fn %{ticker: ticker}, _, _ ->
        batch(
          {Token, :prices},
          ticker,
          fn
            {:ok, prices} ->
              {:ok, Map.get(prices, ticker)}

            _ ->
              {:ok, nil}
          end,
          timeout: 20_000
        )
      end)
    end

    @desc "Explicit Layer 1 and Secured variants of a Layer 1 asset"
    field :variants, non_null(:asset_variants) do
      resolve(fn asset, _, _ -> {:ok, %{asset: asset, layer1: nil, secured: nil, native: nil}} end)
    end
  end

  object :denom do
    field :denom, non_null(:string)
  end

  @desc "Metadata for a token"
  object :metadata do
    field :symbol, non_null(:string)
    field :decimals, non_null(:integer)
    field :description, :string
    field :display, :string
    field :name, :string
    field :uri, :string
    field :uri_hash, :string
  end

  @desc "Price data for a token"
  node object(:price) do
    @desc "Current price, 12 decimal places"
    field :source, non_null(:price_source)
    field :current, :bigint
    field :change_day, :float
    field :mcap, :bigint
    field :timestamp, non_null(:timestamp)
  end

  enum :price_source do
    value(:coingecko)
    value(:fin)
    value(:tor)
    value(:none)
  end

  object :asset_variants do
    @desc "The THORChain layer 1 asset string (eg BTC.BTC, THOR.RUNE, GAIA.ATOM)"
    field :layer1, :asset, resolve: &Token.layer1/3
    @desc "The THORChain secured asset string (eg BTC-BTC, GAIA-ATOM)"
    field :secured, :asset, resolve: &Token.secured/3
    @desc "The Cosmos SDK x/bank token denom string (eg btc-btc, rune, uatom)"
    field :native, :denom, resolve: &Token.native/3
  end

  enum :asset_type do
    value(:layer_1)
    value(:secured)
    value(:native)
    value(:synth)
  end
end
