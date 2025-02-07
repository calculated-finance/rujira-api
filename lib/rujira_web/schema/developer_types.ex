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
  object :code do
    field :id, non_null(:integer)
    field :checksum, non_null(:string)
    field :creator, non_null(:address)

    field :contracts, non_null(list_of(non_null(:contract))) do
      resolve(&Resolvers.Developer.contracts/3)
    end
  end

  object :contract do
    field :address, non_null(:address)
    field :admin, :address
    @desc "JSON encoded response to a { config: {} } request"
    field :config, :string do
      resolve(&Resolvers.Developer.config/3)
    end
  end
end
