defmodule RujiraWeb.Fragments.BalanceFragments do
  alias RujiraWeb.Fragments.AssetFragments

  @asset_fragment AssetFragments.get_asset_fragment()

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
      claimable
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
     claimable
    }
  }
  #{@utxo_fragment}
  #{@asset_fragment}
  """

  def get_layer1_balance_fragment(), do: @layer1_balance_fragment
  def get_balance_fragment(), do: @balance_fragment
end
