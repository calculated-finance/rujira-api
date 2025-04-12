defmodule RujiraWeb.Schema.BalanceTypes do
  use Absinthe.Schema.Notation

  @desc "The balance of a token or coin on a layer 1 chain"
  object :layer_1_balance do
    field :asset, non_null(:asset)
    field :amount, non_null(:bigint)

    field :utxos, list_of(non_null(:utxo)) do
      resolve(&RujiraWeb.Resolvers.Balance.utxos/3)
    end

    field :tcy, :thorchain_tcy do
      resolve(&RujiraWeb.Resolvers.Thorchain.tcy/3)
    end
  end

  @desc "Relacement for layer_1_balance"
  object :balance do
    field :asset, non_null(:asset)
    field :amount, non_null(:bigint)
    field :utxos, list_of(non_null(:utxo))

    field :tcy, :thorchain_tcy do
      resolve(&RujiraWeb.Resolvers.Thorchain.tcy/3)
    end
  end

  object :utxo do
    field :o_index, non_null(:integer)
    field :o_tx_hash, non_null(:string)
    field :value, non_null(:bigint)
    field :script_hex, non_null(:string)
    field :o_tx_hex, non_null(:string)
    field :is_coinbase, :boolean
    field :address, non_null(:string)
  end
end
