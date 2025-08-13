defmodule Rujira.Chains.Utxo do
  @moduledoc """
  Implements the base UTXO adapter for Bitcoin-style blockchains.
  """
  defmacro __using__(opts) do
    asset = Keyword.fetch!(opts, :asset)
    chain = Keyword.fetch!(opts, :chain)
    decimals = Keyword.fetch!(opts, :decimals)

    quote do
      @asset unquote(asset)
      @chain unquote(chain)
      @decimals unquote(decimals)

      @api "https://gql-router.xdefi.services/graphql"

      def client do
        Tesla.client(middleware())
      end

      def middleware do
        [
          {Tesla.Middleware.BaseUrl, @api},
          Tesla.Middleware.JSON,
          {Tesla.Middleware.Headers,
           [
             {"apollographql-client-name", "docs-indexers-api"},
             {"apollographql-client-version", "v1.0"}
           ]}
        ]
      end

      def balances(address, _assets) do
        query = """
        query GetBalances($address: String!) {
          #{@chain} {
            balances(address: $address) {
              amount {
                value
              }
            }
          }
        }
        """

        body = %{"query" => query, "variables" => %{"address" => address, "page" => 0}}

        with {:ok, %{@chain => %{"balances" => [%{"amount" => %{"value" => amount}}]}}} <-
               fetch(body),
             {amount, ""} <- Integer.parse(amount) do
          {:ok,
           [
             %{
               amount: amount,
               asset: Rujira.Assets.from_string(@asset)
             }
           ]}
        end
      end

      def utxos(address) do
        query = """
        query GetUnspentTxOutputsV5($address: String!, $page: Int!) {
          #{@chain} {
            unspentTxOutputsV5(address: $address, page: $page) {
              oIndex
              oTxHash
              value {
                value
              }
              scriptHex
              oTxHex
              isCoinbase
              address
            }
          }
        }
        """

        body = %{"query" => query, "variables" => %{"address" => address, "page" => 0}}

        with {:ok, %{@chain => %{"unspentTxOutputsV5" => utxos}}} <- fetch(body) do
          {:ok, Enum.map(utxos, &cast_utxo/1)}
        end
      end

      defp fetch(query) do
        case Tesla.post(client(), "", query) do
          %{status: 200, body: %{"data" => nil, "errors" => errors}} ->
            {:error, Enum.map(errors, & &1["message"])}

          {:ok, %{status: 200, body: %{"data" => data}}} ->
            {:ok, data}

          {:ok, %{status: status}} ->
            {:error, "status #{status}"}

          {:error, err} ->
            {:error, err}
        end
      end

      defp cast_utxo(%{
             "oIndex" => oIndex,
             "oTxHash" => oTxHash,
             "value" => %{"value" => value},
             "scriptHex" => scriptHex,
             "oTxHex" => oTxHex,
             "isCoinbase" => isCoinbase,
             "address" => address
           }) do
        {value, ""} = Integer.parse(value)

        %{
          o_index: oIndex,
          o_tx_hash: oTxHash,
          script_hex: scriptHex,
          o_tx_hex: oTxHex,
          is_coinbase: isCoinbase,
          address: address,
          value: value
        }
      end
    end
  end
end
