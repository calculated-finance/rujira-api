defmodule RujiraWeb.Schema.StakingTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.StakingFragments

  @list_query """
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

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on StakingPool {
        ...StakingPoolFragment
      }
    }
  }
  #{get_staking_pool_fragment()}
  """

  @account_query """
  query($id: ID!) {
    node(id: $id) {
      ... on StakingAccount {
        ...StakingAccountFragment
      }
    }
  }
  #{get_staking_account_fragment()}
  """

  test "staking flow", %{
    conn: conn,
    account_empty: empty_account,
    account_populated: populated_account
  } do
    %{"data" => %{"staking" => %{"single" => single, "dual" => _}}} =
      post(conn, "/api", %{"query" => @list_query}) |> json_response(200)

    resp =
      post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => single["id"]}})
      |> json_response(200)

    assert Map.get(resp, "errors") == nil

    Enum.each([empty_account, populated_account], fn acct ->
      acct_gid =
        Base.encode64(
          "StakingAccount:#{acct}/#{single["bondAsset"]["variants"]["native"]["denom"]}"
        )

      resp =
        post(conn, "/api", %{"query" => @account_query, "variables" => %{"id" => acct_gid}})
        |> json_response(200)

      assert Map.get(resp, "errors") == nil
    end)
  end
end
