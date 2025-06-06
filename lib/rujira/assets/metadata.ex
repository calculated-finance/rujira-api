defmodule Rujira.Assets.Metadata do
  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Thornode
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse

  use Memoize
  defstruct [:decimals, :description, :display, :name, :symbol, :uri, :uri_hash]

  @type t :: %__MODULE__{
          decimals: integer(),
          description: String.t(),
          display: String.t(),
          name: String.t(),
          symbol: String.t(),
          uri: String.t(),
          uri_hash: String.t()
        }

  defmemo load_metadata(asset) do
    q = %QueryDenomMetadataRequest{denom: asset.id}

    with {:ok, %QueryDenomMetadataResponse{metadata: metadata}} <-
           Thornode.query(&Stub.denom_metadata/2, q) do
      {:ok,
       %__MODULE__{
         description: metadata.description,
         display: metadata.display,
         name: metadata.name,
         symbol: metadata.symbol,
         uri: metadata.uri,
         uri_hash: metadata.uri_hash
       }}
    else
      _ -> {:ok, %__MODULE__{symbol: asset.ticker}}
    end
  end
end
