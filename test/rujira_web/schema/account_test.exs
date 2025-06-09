defmodule RujiraWeb.Schema.AccountTest do
  use RujiraWeb.ConnCase

  import RujiraWeb.Fragments.AccountFragments

  @accounts Application.compile_env(:rujira, :accounts)
  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

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

  test "layer 1 account", %{conn: conn} do
    Enum.each([@empty_account, @populated_account], fn acct ->
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
