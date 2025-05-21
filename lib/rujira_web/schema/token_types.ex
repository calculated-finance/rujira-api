defmodule RujiraWeb.Schema.TokenTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:asset) do
    field :asset, non_null(:asset_string), resolve: &RujiraWeb.Resolvers.Token.string/3
    field :type, non_null(:asset_type)
    field :chain, non_null(:chain), resolve: &RujiraWeb.Resolvers.Token.chain/3
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3

    field :price, :price do
      resolve(fn %{ticker: ticker}, _, _ ->
        batch({RujiraWeb.Resolvers.Token, :prices}, ticker, fn x ->
          with {:ok, prices} <- x do
            {:ok, map(Map.get(prices, ticker))}
          end
        end)
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
  end

  @desc "Price data for a token"
  object :price do
    @desc "Current price, 12 decimal places"
    field :current, :bigint
    field :change_day, :float
    field :mcap, :bigint
  end

  object :asset_variants do
    @desc "The THORChain layer 1 asset string (eg BTC.BTC, THOR.RUNE, GAIA.ATOM)"
    field :layer1, :asset, resolve: &RujiraWeb.Resolvers.Token.layer1/3
    @desc "The THORChain secured asset string (eg BTC-BTC, GAIA-ATOM)"
    field :secured, :asset, resolve: &RujiraWeb.Resolvers.Token.secured/3
    @desc "The Cosmos SDK x/bank token denom string (eg btc-btc, rune, uatom)"
    field :native, :denom, resolve: &RujiraWeb.Resolvers.Token.native/3
  end

  enum :asset_type do
    value(:layer_1)
    value(:secured)
    value(:native)
    value(:synth)
  end

  defp map(%{price: price, change: change, mcap: mcap}),
    do: %{current: price, change_day: change, mcap: mcap}

  defp map(nil), do: nil
end
