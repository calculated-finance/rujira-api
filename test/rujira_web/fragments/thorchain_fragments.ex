defmodule RujiraWeb.Fragments.ThorchainFragments do
  @moduledoc false
  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments

  @asset_fragment AssetFragments.get_asset_fragment()

  @layer_1_balance_fragment BalanceFragments.get_layer1_balance_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()

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

  @quote_fees_fragment """
  fragment ThorchainQuoteFeesFragment on ThorchainQuoteFees {
    asset {
      ...AssetFragment
    }
    affiliate
    outbound
    liquidity
    total
    slippageBps
    totalBps
  }
  #{@asset_fragment}
  """

  @quote_fragment """
  fragment ThorchainQuoteFragment on ThorchainQuote {
    assetIn {
      ...Layer1BalanceFragment
    }
    inboundAddress
    inboundConfirmationBlocks
    inboundConfirmationSeconds
    outboundDelayBlocks
    outboundDelaySeconds
    fees {
      ...ThorchainQuoteFeesFragment
    }
    router
    expiry
    warning
    notes
    dustThreshold
    recommendedMinAmountIn
    recommendedGasRate
    gasRateUnits
    memo
    expectedAmountOut
    expectedAssetOut {
      ...Layer1BalanceFragment
    }
    maxStreamingQuantity
    streamingSwapBlocks
    streamingSwapSeconds
    totalSwapSeconds
  }
  #{@quote_fees_fragment}
  #{@layer_1_balance_fragment}
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

  @tor_candle_fragment """
  fragment ThorchainTorCandleFragment on ThorchainTorCandle {
    resolution
    high
    low
    open
    close
    bin
  }
  """

  @liquidity_provider_fragment """
  fragment ThorchainLiquidityProviderFragment on ThorchainLiquidityProvider {
    asset {
      ...AssetFragment
    }
    runeAddress
    assetAddress
    lastAddHeight
    lastWithdrawHeight
    units
    pendingRune
    pendingAsset
    pendingTxId
    runeDepositValue
    assetDepositValue
    runeRedeemValue
    assetRedeemValue
    valueUsd
  }
  #{@asset_fragment}
  """

  @tx_id_fragment """
  fragment ThorchainTxIdFragment on ThorchainTxId {
    blockHeight
    txIndex
  }
  """

  @layer1_tx_fragment """
  fragment ThorchainLayer1TxFragment on ThorchainLayer1Tx {
    id
    chain
    fromAddress
    toAddress
    coins {
      ...BalanceFragment
    }
    gas {
     ...BalanceFragment
    }
    memo
  }
  #{@balance_fragment}
  """

  @block_event_attribute_fragment """
  fragment ThorchainBlockEventAttributeFragment on ThorchainBlockEventAttribute {
    key
    value
  }
  """

  @block_event_fragment """
  fragment ThorchainBlockEventFragment on ThorchainBlockEvent {
    type
    attributes {
      ...ThorchainBlockEventAttributeFragment
    }
  }
  #{@block_event_attribute_fragment}
  """

  @block_tx_result_fragment """
  fragment ThorchainTxResultFragment on ThorchainTxResult {
    code
    data
    log
    info
    gasWanted
    gasUsed
    codespace
    events {
      ...ThorchainBlockEventFragment
    }
  }
  #{@block_event_fragment}
  """

  @block_tx_fragment """
  fragment ThorchainBlockTxFragment on ThorchainBlockTx {
    hash
    txData
    result {
      ...ThorchainTxResultFragment
    }
  }
  #{@block_tx_result_fragment}
  """

  @block_header_fragment """
  fragment ThorchainBlockHeaderFragment on ThorchainBlockHeader {
    chainId
    height
    time
  }
  """

  @block_id_fragment """
  fragment ThorchainBlockIdFragment on ThorchainBlockId {
    hash
  }
  """

  @block_fragment """
  fragment ThorchainBlockFragment on ThorchainBlock {
    id {
      ...ThorchainBlockIdFragment
    }
    header {
      ...ThorchainBlockHeaderFragment
    }
    beginBlockEvents {
      ...ThorchainBlockEventFragment
    }
    endBlockEvents {
      ...ThorchainBlockEventFragment
    }
    txs {
      ...ThorchainBlockTxFragment
    }
  }
  #{@block_id_fragment}
  #{@block_header_fragment}
  #{@block_event_fragment}
  #{@block_tx_fragment}
  """

  @thorchain_observed_tx_fragment """
  fragment ThorchainObservedTxFragment on ThorchainObservedTx {
    tx {
      ...ThorchainLayer1TxFragment
    }
    status
  }
  #{@layer1_tx_fragment}
  """

  @tx_in_fragment """
  fragment ThorchainTxInFragment on ThorchainTxIn {
    observedTx {
      ...ThorchainObservedTxFragment
    }
    finalizedHeight
    finalizedEvents {
      ...ThorchainBlockEventFragment
    }
  }
  #{@thorchain_observed_tx_fragment}
  #{@block_event_fragment}
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

  def get_thorchain_inbound_address_fragment, do: @inbound_address_fragment
  def get_thorchain_pool_fragment, do: @pool_fragment
  def get_thorchain_tcy_fragment, do: @thorchain_tcy_fragment
  def get_thorchain_oracle_fragment, do: @thorchain_oracle_fragment
  def get_thorchain_block_fragment, do: @block_fragment
  def get_thorchain_block_tx_fragment, do: @block_tx_fragment
  def get_thorchain_block_tx_result_fragment, do: @block_tx_result_fragment
  def get_thorchain_block_id_fragment, do: @block_id_fragment
  def get_thorchain_layer1_tx_fragment, do: @layer1_tx_fragment
  def get_thorchain_tx_id_fragment, do: @tx_id_fragment
  def get_thorchain_tx_in_fragment, do: @tx_in_fragment
  def get_thorchain_quote_fragment, do: @quote_fragment
  def get_thorchain_tor_candle_fragment, do: @tor_candle_fragment
  def get_thorchain_liquidity_provider_fragment, do: @liquidity_provider_fragment
end
