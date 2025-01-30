defmodule RujiraWeb.Schema.TokenTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:asset) do
    field :asset, non_null(:asset_string)
    field :type, non_null(:asset_type)
    field :chain, non_null(:chain)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3

    field :price, :price do
      resolve(fn %{asset: asset}, _, _ ->
        sym = Rujira.Assets.symbol(asset)

        batch({RujiraWeb.Resolvers.Token, :prices}, sym, fn x ->
          with {:ok, prices} <- x do
            {:ok, map(Map.get(prices, sym))}
          end
        end)
      end)
    end

    @desc "Explicit Layer 1 and Secured variants of a Layer 1 asset"
    field :variants, non_null(:asset_variants), resolve: &RujiraWeb.Resolvers.Token.variants/3
  end

  node object(:denom) do
    field :denom, non_null(:string)
    field :metadata, non_null(:metadata), resolve: &RujiraWeb.Resolvers.Token.metadata/3

    field :price, :price do
      resolve(fn %{denom: denom}, _, _ ->
        sym = Rujira.Denoms.symbol(denom)

        batch({RujiraWeb.Resolvers.Token, :prices}, sym, fn x ->
          with {:ok, prices} <- x do
            {:ok, map(Map.get(prices, sym))}
          end
        end)
      end)
    end

    # , resolve: &RujiraWeb.Resolvers.Token.price/3
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
  end

  object :asset_variants do
    @desc "The THORChain layer 1 asset string (eg BTC.BTC, THOR.RUNE, GAIA.ATOM)"
    field :layer1, non_null(:asset)
    @desc "The THORChain secured asset string (eg BTC-BTC, GAIA-ATOM)"
    field :secured, :asset
    @desc "The Cosmos SDK x/bank token denom string (eg btc-btc, rune, uatom)"
    field :native, :denom
  end

  enum :asset_type do
    value(:layer_1)
    value(:secured)
    value(:native)
  end

  defp map(%{price: price, change: change}), do: %{current: price, change: change}
  defp map(nil), do: nil
end
