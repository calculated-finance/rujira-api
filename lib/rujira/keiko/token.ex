defmodule Rujira.Keiko.Token do
  @moduledoc false

  alias Rujira.Assets.Asset
  alias Rujira.Assets.Metadata

  defstruct [
    :admin,
    :asset
  ]

  @type t :: %__MODULE__{
          admin: String.t(),
          asset: Asset.t()
        }

  def from_query(%{
        "create" => %{
          "description" => description,
          "display" => display,
          "name" => name,
          "png_url" => png_url,
          "svg_url" => svg_url,
          "symbol" => symbol,
          "uri" => uri,
          "uri_hash" => uri_hash,
          "denom_admin" => denom_admin
        }
      }) do
    {:ok,
     %__MODULE__{
       admin: denom_admin,
       asset: %Asset{
         id: "x/#{String.downcase(symbol)}",
         type: :native,
         chain: "THOR",
         symbol: String.upcase(symbol),
         ticker: String.upcase(symbol),
         metadata: %Metadata{
           description: description,
           display: display,
           name: name,
           png_url: png_url,
           svg_url: svg_url,
           symbol: String.upcase(symbol),
           uri: uri,
           uri_hash: uri_hash,
           decimals: 8
         }
       }
     }}
  end
end
