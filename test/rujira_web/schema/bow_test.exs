defmodule RujiraWeb.Schema.BowTest do
  use RujiraWeb.ConnCase

  alias Rujira.Deployments

  import RujiraWeb.Fragments.BowFragments

  @accounts Application.compile_env(:rujira, :accounts)

  @empty_account Keyword.fetch!(@accounts, :empty_account)
  @populated_account Keyword.fetch!(@accounts, :populated_account)

  @query """
  query {
    bow {
      ...BowPoolFragment
    }
  }
  #{get_bow_pool_fragment()}
  """

  test "bow", %{conn: conn} do
    conn = post(conn, "/api", %{"query" => @query})
    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  @query """
  query($id: ID!) {
    node(id: $id) {
      ... on BowPool {
        ...BowPoolFragment
      }
    }
  }
  #{get_bow_pool_fragment()}
  """

  test "bow pool", %{conn: conn} do
    bow_pool = Deployments.get_target(Rujira.Bow, "ruji-rune")
    id = Base.encode64("BowPool:#{bow_pool.address}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => id}
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
          bow {
            ...BowAccountFragment
          }
        }
      }
    }
  }
  #{get_bow_account_fragment()}
  """
  test "bow account empty from layer1 account", %{conn: conn} do
    encoded_id =
      Base.encode64("Layer1Account:thor:#{@empty_account}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end

  test "bow account populated from layer1 account", %{conn: conn} do
    encoded_id =
      Base.encode64("Layer1Account:thor:#{@populated_account}")

    conn =
      post(conn, "/api", %{
        "query" => @query,
        "variables" => %{"id" => encoded_id}
      })

    res = json_response(conn, 200)
    assert Map.get(res, "errors") == nil
  end
end
