defmodule RujiraWeb.Schema.DeveloperTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  alias RujiraWeb.Resolvers

  @desc "A merge_pool represents the configuration about a rujira-merge contract"
  object :developer do
    field :codes, non_null(list_of(non_null(:code))) do
      resolve(&Resolvers.Developer.codes/3)
    end
  end

  @desc "A stored wasm binary"
  node object(:code) do
    field :checksum, non_null(:string)
    field :creator, non_null(:address)

    field :contracts, non_null(list_of(non_null(:contract))) do
      resolve(&Resolvers.Developer.contracts/3)
    end
  end

  node object(:contract) do
    field :address, :address

    field :info, :contract_info do
      resolve(&Resolvers.Developer.info/3)
    end

    @desc "JSON encoded response to a { config: {} } request"
    field :config, :string do
      resolve(&Resolvers.Developer.config/3)
    end

    field :query_smart, :string do
      arg(:query, :string)
      resolve(&Resolvers.Developer.query_smart/3)
    end

    field :state, non_null(list_of(:state_entry)) do
      resolve(&Resolvers.Developer.state/3)
    end
  end

  object :contract_info do
    field :code_id, non_null(:integer)
    field :creator, non_null(:address)
    field :admin, :address
    field :label, non_null(:string)
    field :created, :tx_position
    field :ibc_port_id, :string
    field :extension, :string
  end

  object :state_entry do
    field :key, :string
    field :key_ascii, :string
    field :value, :string
  end

  object :tx_position do
    field :block_height, non_null(:integer)
    field :tx_index, non_null(:integer)
  end
end
