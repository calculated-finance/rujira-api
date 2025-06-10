defmodule RujiraWeb.Schema.AccountTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.AccountFragments

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on Layer1Account {
        ...Layer1AccountFragment
      }
    }
  }
  #{get_layer1_account_fragment()}
  """

  test "layer 1 account", %{
    conn: conn,
    account_empty: empty_account,
    account_populated: populated_account
  } do
    Enum.each([empty_account, populated_account], fn acct ->
      resp =
        post(conn, "/api", %{
          "query" => @query,
          "variables" => %{"id" => Base.encode64("Layer1Account:thor:#{acct}")}
        })

      res = json_response(resp, 200)
      assert Map.get(res, "errors") == nil
    end)
  end
end
