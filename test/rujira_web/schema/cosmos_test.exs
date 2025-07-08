defmodule RujiraWeb.Schema.CosmosTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.CosmosFragments

  @terra_id "Q29zbW9zQWNjb3VudDp0ZXJyYTp0ZXJyYTF3ZmR6ZXM1NmU5MGw1ejR0dndod3JlNGhqeWxrbHIyNXAwMzc5cw=="
  @terra2_id "Q29zbW9zQWNjb3VudDp0ZXJyYTI6dGVycmExd2ZkemVzNTZlOTBsNXo0dHZ3aHdyZTRoanlsa2xyMjVwMDM3OXM="

  @node_query """
  query($id: ID!) {
    node(id: $id) {
      ... on CosmosAccount {
        ...CosmosAccountFragment
      }
    }
  }
  #{get_cosmos_account_fragment()}
  """

  test "terra and terra2 account lookup", %{
    conn: conn
  } do
    resp = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => @terra_id}})
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil

    resp = post(conn, "/api", %{"query" => @node_query, "variables" => %{"id" => @terra2_id}})
    res = json_response(resp, 200)
    assert Map.get(res, "errors") == nil
  end
end
