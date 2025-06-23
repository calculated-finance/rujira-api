defmodule RujiraWeb.Schema.DeveloperTypes do
  @moduledoc """
  Defines GraphQL types for developer tools and utilities in the Rujira API.

  This module contains the type definitions and field resolvers for developer-related
  GraphQL objects, including code management and contract utilities.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias RujiraWeb.Resolvers

  @desc "Access to smart contract development and inspection tools"
  object :developer do
    field :codes, non_null(list_of(non_null(:code))) do
      resolve(&Resolvers.Developer.codes/3)
    end
  end

  @desc "A compiled WebAssembly (WASM) binary for smart contracts"
  node object(:code) do
    field :checksum, non_null(:string)
    field :creator, non_null(:address)

    field :contracts, non_null(list_of(non_null(:contract))) do
      resolve(&Resolvers.Developer.contracts/3)
    end
  end

  @desc "An instantiated smart contract with query and state access"
  node object(:contract) do
    field :address, :address

    field :info, :contract_info do
      resolve(&Resolvers.Developer.info/3)
    end

    field :config, :string do
      resolve(&Resolvers.Developer.config/3)
    end

    field :query_smart, :string do
      @desc "JSON-encoded query message to send to the contract"
      arg(:query, :string)
      resolve(&Resolvers.Developer.query_smart/3)
    end

    field :state, non_null(list_of(:state_entry)) do
      resolve(&Resolvers.Developer.state/3)
    end
  end

  @desc "Metadata and configuration for a deployed smart contract"
  object :contract_info do
    field :code_id, non_null(:integer)
    field :creator, non_null(:address)
    field :admin, :address
    field :label, non_null(:string)
    field :created, :tx_position
    field :ibc_port_id, :string
    field :extension, :string
  end

  @desc "Key-value pair in a contract's state storage"
  object :state_entry do
    field :key, :string
    field :key_ascii, :string
    field :value, :string
  end

  @desc "Blockchain position of a transaction"
  object :tx_position do
    field :block_height, non_null(:integer)
    field :tx_index, non_null(:integer)
  end
end
