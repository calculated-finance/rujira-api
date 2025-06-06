defmodule RujiraWeb.Schema.StakingTest do
  use RujiraWeb.ConnCase
  alias Rujira.Deployments

  @accounts Application.compile_env(:rujira, :accounts)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

  @staking_status_fragment """
  fragment StakingStatusFragment on StakingStatus {
    accountBond
    accountRevenue
    liquidBondShares
    liquidBondSize
    pendingRevenue
  }
  """

  @revenue_converter_type_fragment """
  fragment RevenueConverterTypeFragment on RevenueConverterType {
    address
    contract {
      label
      admin
    }
    executeMsg
    limit
  }
  """

  @revenue_converter_fragment """
  fragment RevenueConverterFragment on RevenueConverter {
    balances {
      amount
      asset {
        asset
      }
    }
    targetAssets {
      asset
    }
    targetAddresses
  }
  """

  @staking_revenue_point_fragment """
  fragment StakingRevenuePointFragment on StakingRevenuePoint {
    amount
    timestamp
  }
  """

  @staking_summary_fragment """
  fragment StakingSummaryFragment on StakingSummary {
    apr
    revenue {
      ...StakingRevenuePointFragment
    }
    revenue1
    revenue7
    revenue30
  }
  #{@staking_revenue_point_fragment}
  """

  @staking_pool_fragment """
  fragment StakingPoolFragment on StakingPool {
    id
    address
    contract {
      label
      admin
    }
    bondAsset {
      asset
    }
    revenueAsset {
      asset
    }
    revenueConverter {
      ...RevenueConverterTypeFragment
    }
    status {
      ...StakingStatusFragment
    }
    summary {
      ...StakingSummaryFragment
    }
  }
  #{@staking_status_fragment}
  #{@revenue_converter_type_fragment}
  #{@staking_summary_fragment}
  """

  @staking_account_fragment """
  fragment StakingAccountFragment on StakingAccount {
    id
    pool {
      id
      address
    }
    account
    bonded {
      amount
      asset {
        asset
      }
    }
    liquid {
      amount
      asset {
        asset
      }
    }
    pendingRevenue {
      amount
      asset {
        asset
      }
    }
  }
  """

  @query """
  query {
    staking {
      single {
        ...StakingPoolFragment
      }
      dual {
        ...StakingPoolFragment
      }
      revenue {
        ...RevenueConverterFragment
      }
    }
  }
  #{@staking_pool_fragment}
  #{@revenue_converter_fragment}
  """

  test "staking", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on StakingPool {
        ...StakingPoolFragment
      }
    }
  }
  #{@staking_pool_fragment}
  """

  test "staking pool", %{conn: conn} do
    staking_pool =
      Deployments.get_target(Rujira.Staking.Pool, "ruji")
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "id" =>
            Base.encode64(
              "StakingPool:#{staking_pool.address}"
            )
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on StakingAccount {
        ...StakingAccountFragment
      }
    }
  }
  #{@staking_account_fragment}
  """

  test "staking account populated", %{conn: conn} do
    staking_pool =
      Deployments.get_target(Rujira.Staking.Pool, "ruji")
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "id" =>
            Base.encode64(
              "StakingAccount:#{staking_pool.address}/#{@populated_account}"
            )
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "staking account empty", %{conn: conn} do
    staking_pool =
      Deployments.get_target(Rujira.Staking.Pool, "ruji")
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "id" =>
            Base.encode64(
              "StakingAccount:#{staking_pool.address}/#{@empty_account}"
            )
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on Layer1Account {
        id
        account {
          staking {
          single {
            ...StakingAccountFragment
          }
          dual {
            ...StakingAccountFragment
          }
          }
        }
      }
    }
  }
  #{@staking_account_fragment}
  """

  test "layer1 account staking", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "id" =>
            Base.encode64(
              "Layer1Account:thor:#{@populated_account}"
            )
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "layer1 account staking empty", %{conn: conn} do
    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{
          "id" =>
            Base.encode64(
              "Layer1Account:thor:#{@empty_account}"
            )
        }
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
