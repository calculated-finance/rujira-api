defmodule RujiraWeb.Schema.StakingTest do
  use RujiraWeb.ConnCase
  alias Rujira.Deployments

  @accounts Application.compile_env(:rujira, :accounts)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

  import RujiraWeb.Fragments.StakingFragments

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
  #{get_staking_pool_fragment()}
  #{get_revenue_converter_fragment()}
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
  #{get_staking_pool_fragment()}
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
  #{get_staking_account_fragment()}
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
  #{get_staking_account_fragment()}
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
