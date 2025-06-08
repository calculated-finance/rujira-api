defmodule RujiraWeb.Fragments.ThorchainFragments do
  alias RujiraWeb.Fragments.AssetFragments

  @asset_fragment AssetFragments.get_asset_fragment()

  @inbound_address_fragment """
  fragment ThorchainInboundAddressFragment on ThorchainInboundAddress {
    address
    chain
    chainLpActionsPaused
    chainTradingPaused
    dustThreshold
    gasRate
    gasRateUnits
    globalTradingPaused
    halted
    id
    outboundFee
    outboundTxSize
    pubKey
    router
  }
  """

  @pool_fragment """
  fragment ThorchainPoolFragment on ThorchainPool {
    asset {
      ...AssetFragment
    }
    assetTorPrice
    balanceAsset
    balanceRune
    decimals
    derivedDepthBps
    id
    loanCollateral
    loanCollateralRemaining
    loanCr
    lpUnits
    pendingInboundAsset
    pendingInboundRune
    poolUnits
    saversCapacityRemaining
    saversDepth
    saversFillBps
    saversUnits
    shortCode
    status
    synthMintPaused
    synthSupply
    synthSupplyRemaining
    synthUnits
  }
  #{@asset_fragment}
  """

  @thorchain_tcy_fragment """
  fragment ThorchainTcyFragment on ThorchainTcy {
    claimable
  }
  """

  @thorchain_oracle_fragment """
  fragment ThorchainOracleFragment on ThorchainOracle {
    id
    asset {
      ...AssetFragment
    }
    price
  }
  #{@asset_fragment}
  """

  def get_thorchain_inbound_address_fragment(), do: @inbound_address_fragment
  def get_thorchain_pool_fragment(), do: @pool_fragment
  def get_thorchain_tcy_fragment(), do: @thorchain_tcy_fragment
  def get_thorchain_oracle_fragment(), do: @thorchain_oracle_fragment
end
