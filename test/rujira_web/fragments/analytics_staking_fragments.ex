defmodule RujiraWeb.Fragments.AnalyticsStakingFragments do
  @moduledoc false

  @point_fragment """
  fragment PointFragment on Point {
    value
    movingAvg
  }
  """

  @analytics_staking_bins_fragment """
  fragment AnalyticsStakingBinsFragment on AnalyticsStakingBins {
    resolution
    bin
    lpWeight
    # Revenue data in USD
    totalRevenue {
      ...PointFragment
    }
    accountRevenue {
      ...PointFragment
    }
    liquidRevenue {
      ...PointFragment
    }

    # APR/APY data
    accountApr {
      ...PointFragment
    }
    liquidApy {
      ...PointFragment
    }
    accountRevenuePerShare {
      ...PointFragment
    }

    # Balance data in bond denom
    totalBalanceStaked {
      ...PointFragment
    }
    accountBalanceStaked {
      ...PointFragment
    }
    liquidBalanceStaked {
      ...PointFragment
    }

    # Calculated weights
    liquidWeight

    # Value data in USD
    totalValueStaked {
      ...PointFragment
    }
    accountValueStaked {
      ...PointFragment
    }
    liquidValueStaked {
      ...PointFragment
    }

    # Inflow data in bond denom
    inflowAccountStaked {
      ...PointFragment
    }
    inflowLiquidStaked {
      ...PointFragment
    }
    inflowTotalStaked {
      ...PointFragment
    }

    # Outflow data in bond denom
    outflowAccountStaked {
      ...PointFragment
    }
    outflowLiquidStaked {
      ...PointFragment
    }
    outflowTotalStaked {
      ...PointFragment
    }

    # Calculated net flows
    netFlowAccountStaked
    netFlowLiquidStaked
    netFlowTotalStaked
  }
  #{@point_fragment}
  """

  @analytics_staking_connection_fragment """
  fragment AnalyticsStakingConnectionFragment on AnalyticsStakingBinsConnection {
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
    }
    edges {
      cursor
      node {
        ...AnalyticsStakingBinsFragment
      }
    }
  }
  #{@analytics_staking_bins_fragment}
  """

  def get_point_fragment, do: @point_fragment
  def get_analytics_staking_bins_fragment, do: @analytics_staking_bins_fragment
  def get_analytics_staking_connection_fragment, do: @analytics_staking_connection_fragment
end
