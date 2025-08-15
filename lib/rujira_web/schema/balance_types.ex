defmodule RujiraWeb.Schema.BalanceTypes do
  @moduledoc """
  Defines GraphQL types for balance-related data in the Rujira API.

  This module contains the type definitions for balance-related
  GraphQL objects, including layer 1 balances and their associated metadata.
  """

  use Absinthe.Schema.Notation

  alias Rujira.Assets
  alias Rujira.Prices
  alias RujiraWeb.Resolvers.Balance
  alias RujiraWeb.Resolvers.Thorchain

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:asset)

    field :amount, non_null(:bigint) do
      resolve(fn %{amount: amount}, _, _ ->
        Balance.parse(amount)
      end)
    end

    field :utxos, list_of(non_null(:utxo)) do
      resolve(&Balance.utxos/3)
    end

    field :tcy, :thorchain_tcy do
      resolve(&Thorchain.tcy/3)
    end

    field :value_usd, non_null(:bigint) do
      resolve(fn %{amount: amount, asset: %{ticker: ticker} = asset}, _, _ ->
        {:ok, Prices.value_usd(ticker, amount, Assets.decimals(asset))}
      end)
    end
  end

  @desc "Relacement for layer_1_balance"
  object :balance do
    field :asset, non_null(:asset)

    field :amount, non_null(:bigint) do
      resolve(fn %{amount: amount}, _, _ ->
        Balance.parse(amount)
      end)
    end

    field :utxos, list_of(non_null(:utxo))

    field :tcy, :thorchain_tcy do
      resolve(&Thorchain.tcy/3)
    end

    field :value_usd, non_null(:bigint) do
      resolve(fn %{amount: amount, asset: %{ticker: ticker} = asset}, _, _ ->
        {:ok, Prices.value_usd(ticker, amount, Assets.decimals(asset))}
      end)
    end
  end

  object :utxo do
    field :o_index, non_null(:integer)
    field :o_tx_hash, non_null(:string)
    field :value, non_null(:bigint)
    field :script_hex, non_null(:string)
    field :o_tx_hex, non_null(:string)
    field :is_coinbase, :boolean
    field :address, non_null(:address)
  end
end
