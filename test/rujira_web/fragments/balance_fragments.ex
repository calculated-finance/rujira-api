defmodule RujiraWeb.Fragments.BalanceFragments do
  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.ThorchainFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @thorchain_tcy_fragment ThorchainFragments.get_thorchain_tcy_fragment()

  @utxo_fragment """
  fragment UtxoFragment on Utxo {
    oIndex
    oTxHash
    value
    scriptHex
    oTxHex
    isCoinbase
    address
  }
  """

  @layer1_balance_fragment """
  fragment Layer1BalanceFragment on Layer1Balance {
    asset {
      ...AssetFragment
    }
    amount
    utxos {
      ...UtxoFragment
    }
    tcy {
      pool
      amount
      asset {
        ...AssetFragment
      }
    }
  }
  #{@utxo_fragment}
  #{@asset_fragment}
  """

  @balance_fragment """
  fragment BalanceFragment on Balance {
    asset {
      ...AssetFragment
    }
    amount
    utxos {
      ...UtxoFragment
    }
    tcy {
      ...ThorchainTcyFragment
    }
  }
  #{@utxo_fragment}
  #{@asset_fragment}
  #{@thorchain_tcy_fragment}
  """

  def get_layer1_balance_fragment(), do: @layer1_balance_fragment
  def get_balance_fragment(), do: @balance_fragment
end
