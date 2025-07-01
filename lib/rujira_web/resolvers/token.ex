defmodule RujiraWeb.Resolvers.Token do
  @moduledoc """
  Handles GraphQL resolution for token-related queries and type conversions.

  This module provides resolver functions for working with token assets, including:
  - Converting between different token representations (string, layer1, secured)
  - Resolving native token denominations for different blockchains
  - Supporting various token types including THORChain and KUJI assets
  """
  alias Absinthe.Resolution.Helpers
  alias Rujira.Assets
  alias Rujira.Assets.Asset
  alias Rujira.Chains.Gaia
  alias Rujira.Chains.Kuji
  alias Rujira.Chains.Noble

  def string(%Asset{} = asset, _, _), do: {:ok, Assets.to_string(asset)}
  def layer1(%{asset: %Asset{} = asset}, _, _), do: {:ok, Assets.to_layer1(asset)}
  def secured(%{asset: %Asset{} = asset}, _, _), do: {:ok, Assets.to_secured(asset)}

  @doc """
  Converts an Asset string to a Cosmos SDK x/bank denom string

  For Layer 1 assets, this will return a value if the Layer 1 chain is Cosmos SDK
  For Secured assets, this will return the THORChain x/bank denom string for the secured asset
  """
  def native(%{asset: %Asset{type: :secured, id: id}}, _, _),
    do: {:ok, %{denom: String.downcase(id)}}

  def native(%{asset: %Asset{chain: "THOR"} = a}, _, _) do
    with {:ok, denom} <- Assets.to_native(a) do
      {:ok, %{denom: denom}}
    end
  end

  def native(%{asset: %Asset{chain: "KUJI", symbol: symbol}}, _, _) do
    case Kuji.to_denom(symbol) do
      {:ok, denom} -> {:ok, %{denom: denom}}
      _ -> {:ok, nil}
    end
  end

  def native(%{asset: %Asset{chain: "GAIA", symbol: symbol}}, _, _) do
    case Gaia.to_denom(symbol) do
      {:ok, denom} -> {:ok, %{denom: denom}}
      _ -> {:ok, nil}
    end
  end

  def native(%{asset: %Asset{chain: "NOBLE", symbol: symbol}}, _, _) do
    case Noble.to_denom(symbol) do
      {:ok, denom} -> {:ok, %{denom: denom}}
      _ -> {:ok, nil}
    end
  end

  def native(_, _, _) do
    {:ok, nil}
  end

  def chain(%{chain: chain}, _, _),
    do: {:ok, chain |> String.downcase() |> String.to_existing_atom()}

  def metadata(%Asset{} = asset, _, _) do
    Helpers.async(fn -> Assets.load_metadata(asset) end)
  end

  def price(%Asset{ticker: ticker}, _, _) do
    Helpers.async(fn -> Rujira.Prices.get(ticker) end)
  end

  def quote(%{request: %{to_asset: asset}, expected_amount_out: amount}, _, _) do
    {:ok, %{asset: asset, amount: amount}}
  end
end
