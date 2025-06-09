defmodule RujiraWeb.Schema.MergeTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.MergeFragments

  @accounts Application.compile_env(:rujira, :accounts)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)


  @list_query """
  query {
    merge {
      ...MergePoolFragment
    }
  }
  #{get_merge_pool_fragment()}
  """

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on MergePool {
        ...MergePoolFragment
      }
    }
  }
  #{get_merge_pool_fragment()}
  """

  @account_query """
  query($id: ID!) {
    node(id: $id) {
      ... on MergeAccount {
        ...MergeAccountFragment
      }
    }
  }
  #{get_merge_account_fragment()}
  """

  test "merge pool list, lookup, and both empty+populated accounts", %{conn: conn} do
    # 1) list all pools
    resp = post(conn, "/api", %{"query" => @list_query})
    %{"data" => %{"merge" => pools}} = json_response(resp, 200)
    assert is_list(pools) and length(pools) > 0

    # grab the first one
    pool = hd(pools)

    # 2) lookup that pool via node(id:)
    resp = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => pool["id"]}})
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil

    # 3) test both empty and populated accounts
    Enum.each([@empty_account, @populated_account], fn acct ->
      acc_gid =
        Base.encode64("MergeAccount:#{pool["address"]}/#{acct}")

      resp =
        post(conn, "/api", %{
          "query"     => @account_query,
          "variables" => %{"id" => acc_gid}
        })

      res = json_response(resp, 200)
      assert Map.get(res, "errors") == nil
    end)
  end
end
