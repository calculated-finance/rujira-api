defmodule RujiraWeb.Fragments.VenturesFragments do
  @moduledoc false

  alias RujiraWeb.Fragments.AssetFragments
  alias RujiraWeb.Fragments.BalanceFragments
  alias RujiraWeb.Fragments.PilotFragments

  @asset_fragment AssetFragments.get_asset_fragment()
  @balance_fragment BalanceFragments.get_balance_fragment()
  @pilot_sale_fragment PilotFragments.get_pilot_sale_fragment()

  @ventures_token_fragment """
  fragment VenturesTokenFragment on VenturesToken {
    admin
    asset {
      ...AssetFragment
    }
  }
  #{@asset_fragment}
  """

  @ventures_pool_response_fragment """
  fragment VenturesPoolResponseFragment on VenturesPoolResponse {
    premium
    epoch
    price
    total
  }
  """

  @ventures_pools_response_fragment """
  fragment VenturesPoolsResponseFragment on VenturesPoolsResponse {
    pools {
      ...VenturesPoolResponseFragment
    }
  }
  """

  @ventures_validate_token_response_fragment """
  fragment VenturesValidateTokenResponseFragment on VenturesValidateTokenResponse {
    valid
    message
  }
  """

  @ventures_config_fragment """
  fragment VenturesConfigFragment on VenturesConfig {
    address
    bow {
      admin
      codeId
    }
    fin {
      admin
      codeId
      feeAddress
      feeMaker
      feeTaker
    }
    pilot {
      admin
      codeId
      feeAddress
      feeMaker
      feeTaker
      maxPremium
      deposit {
        ...BalanceFragment
      }
      bidAssets {
        asset {
          ...AssetFragment
        }
        minRaiseAmount
      }
    }
    streams {
      cw1ContractAddress
      payrollFactoryContractAddress
    }
    tokenomics {
      minLiquidity
    }
  }
  #{@balance_fragment}
  #{@asset_fragment}
  """

  @ventures_sale_pilot_fragment """
  fragment VenturesSalePilotFragment on VenturesSalePilot {
    sale {
      ...PilotSaleFragment
    }
    token {
      ...VenturesTokenFragment
    }
    tokenomics {
      categories {
        label
        type
        recipients {
          ... on VenturesTokenomicsRecipientSend {
            address
            amount
          }
          ... on VenturesTokenomicsRecipientSet {
            amount
          }
          ... on VenturesTokenomicsRecipientStream {
            owner
            recipient
            title
            total
            denom
            start_time
            schedule
            vesting_duration_seconds
            unbonding_duration_seconds
          }
        }
      }
    }
    fin
    bow
    termsConditionsAccepted
  }
  #{@pilot_sale_fragment}
  #{@ventures_token_fragment}
  """

  @ventures_sale_fragment """
  fragment VenturesSaleFragment on VenturesSale {
    id
    idx
    title
    description
    url
    beneficiary
    owner
    status
    venture {
      ... on VenturesSalePilot {
        ...VenturesSalePilotFragment
      }
    }
  }
  #{@ventures_sale_pilot_fragment}
  """

  def get_ventures_config_fragment, do: @ventures_config_fragment
  def get_ventures_sale_fragment, do: @ventures_sale_fragment
  def get_ventures_sale_pilot_fragment, do: @ventures_sale_pilot_fragment

  def get_ventures_validate_token_response_fragment,
    do: @ventures_validate_token_response_fragment

  def get_ventures_pool_response_fragment, do: @ventures_pool_response_fragment
  def get_ventures_pools_response_fragment, do: @ventures_pools_response_fragment
end
