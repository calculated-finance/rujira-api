defmodule RujiraWeb.Schema.GQLTestMacros do
  @moduledoc """
  Provides a `generate_gql_tests/1` macro that, given a list of test‐definitions,
  injects one ExUnit `test` block per definition. Each definition is a map with keys:

    - `:name`          – a string, used in `test "GraphQL: {name}"`.
    - `:query`         – the GraphQL query string (including fragments).
    - `:variables`     – a map of variables to send (defaults to `%{}`).
    - `:response_path` – a list of strings, the JSON path into `"data"`.
    - `:type_name`     – the Absinthe type‐name (string) to validate.
    - `:is_list`       – `true` if the response is a list, `false` if a single object.

  Usage in a test module:

      import RujiraWeb.Schema.GQLTestMacros

      @gql_tests [
        %{
          name:          "inbound addresses",
          query:         "...GraphQL with fragment...",
          variables:     %{},
          response_path: ["data", "thorchainV2", "inboundAddresses"],
          type_name:     "ThorchainInboundAddress",
          is_list:       true
        },
        # …more entries…
      ]

      generate_gql_tests(@gql_tests)
  """

  defmacro generate_gql_tests(gql_tests_ast) do
    quote bind_quoted: [gql_tests: gql_tests_ast] do
      for %{name: name,
            query: query,
            variables: vars,
            response_path: path,
            type_name: type_name,
            is_list: is_list} <- gql_tests do

        # Prepare module‐level attributes so they’re available at compile time
        @query_string query
        @vars_map vars
        @resp_path path
        @type_name type_name
        @expect_list is_list

        test "GraphQL: #{name}", %{conn: conn} do
          # Send the GraphQL request
          conn =
            post(conn, "/api", %{
              "query"     => @query_string,
              "variables" => @vars_map
            })

          # 1) HTTP 200 and no errors
          res = json_response(conn, 200)
          assert Map.get(res, "errors") == nil

          # 2) Drill into the JSON at @resp_path
          data_at_path = get_in(res, @resp_path)
          assert not is_nil(data_at_path),
                 "Expected data at #{@resp_path}, got: #{inspect(res)}"

          # 3) If it’s supposed to be a list, ensure non‐empty; else a map
          if @expect_list do
            assert is_list(data_at_path) and length(data_at_path) > 0
            first = hd(data_at_path)
            assert is_map(first)
            RujiraWeb.Schema.GraphQLHelpers.assert_map_has_fields!(first, @type_name)
          else
            assert is_map(data_at_path)
            RujiraWeb.Schema.GraphQLHelpers.assert_map_has_fields!(data_at_path, @type_name)
          end
        end
      end
    end
  end
end
