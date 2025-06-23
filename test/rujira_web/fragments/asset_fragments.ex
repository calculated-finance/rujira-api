defmodule RujiraWeb.Fragments.AssetFragments do
  @moduledoc false

  @metadata_fragment """
  fragment MetadataFragment on Metadata {
    symbol
    decimals
    description
    display
    name
    uri
    uriHash
  }
  """

  @price_fragment """
  fragment PriceFragment on Price {
    id
    source
    current
    changeDay
    mcap
    timestamp
  }
  """

  @denom_fragment """
  fragment DenomFragment on Denom {
    denom
  }
  """

  @asset_fragment_simple """
  fragment AssetFragmentSimple on Asset {
    id
    asset
    type
    chain
  }
  """

  @asset_variants_fragment """
  fragment AssetVariantsFragment on AssetVariants {
    layer1 {
      ...AssetFragmentSimple
    }
    secured {
      ...AssetFragmentSimple
    }
    native {
      ...DenomFragment
    }
  }
  #{@denom_fragment}
  #{@asset_fragment_simple}
  """

  @asset_fragment """
  fragment AssetFragment on Asset {
    id
    asset
    type
    chain
    metadata {
      ...MetadataFragment
    }
    price {
      ...PriceFragment
    }
    variants {
      ...AssetVariantsFragment
    }
  }
  #{@metadata_fragment}
  #{@price_fragment}
  #{@asset_variants_fragment}
  """

  def get_asset_fragment, do: @asset_fragment
  def get_metadata_fragment, do: @metadata_fragment
  def get_price_fragment, do: @price_fragment
  def get_denom_fragment, do: @denom_fragment
  def get_asset_fragment_simple, do: @asset_fragment_simple
  def get_asset_variants_fragment, do: @asset_variants_fragment
end
