defmodule Rujira.Assets.Metadata do
  @moduledoc """
  Module for handling asset metadata in the Rujira application.

  This module provides functionality for querying and processing metadata
  associated with blockchain assets, including token details and descriptions.
  """

  alias Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataRequest
  alias Cosmos.Bank.V1beta1.QueryDenomMetadataResponse
  alias Thornode

  use Memoize

  defstruct [
    :decimals,
    :description,
    :display,
    :name,
    :symbol,
    :uri,
    :uri_hash,
    :png_url,
    :svg_url
  ]

  @type t :: %__MODULE__{
          decimals: integer(),
          description: String.t(),
          display: String.t(),
          name: String.t(),
          symbol: String.t(),
          uri: String.t(),
          uri_hash: String.t(),
          png_url: String.t(),
          svg_url: String.t()
        }

  defmemo load_metadata(asset) do
    q = %QueryDenomMetadataRequest{denom: asset.id}

    case Thornode.query(&Stub.denom_metadata/2, q) do
      {:ok, %QueryDenomMetadataResponse{metadata: metadata}} ->
        {:ok,
         %__MODULE__{
           description: metadata.description,
           display: metadata.display,
           name: metadata.name,
           symbol: metadata.symbol,
           uri: metadata.uri,
           uri_hash: metadata.uri_hash
         }}

      _ ->
        {:ok, %__MODULE__{symbol: asset.ticker}}
    end
  end
end
