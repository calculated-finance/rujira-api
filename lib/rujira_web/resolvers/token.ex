defmodule RujiraWeb.Resolvers.Token do
  alias Rujira.Assets.Asset
  alias Rujira.Assets

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
    with {:ok, denom} <- Rujira.Chains.Kuji.to_denom(symbol) do
      {:ok, %{denom: denom}}
    else
      _ -> {:ok, nil}
    end
  end

  def native(%{asset: %Asset{chain: "GAIA", symbol: symbol}}, _, _) do
    with {:ok, denom} <- Rujira.Chains.Gaia.to_denom(symbol) do
      {:ok, %{denom: denom}}
    else
      _ -> {:ok, nil}
    end
  end

  def native(%{asset: %Asset{chain: "NOBLE", symbol: symbol}}, _, _) do
    with {:ok, denom} <- Rujira.Chains.Noble.to_denom(symbol) do
      {:ok, %{denom: denom}}
    else
      _ -> {:ok, nil}
    end
  end

  def native(_, _, _) do
    {:ok, nil}
  end

  def chain(%{chain: chain}, _, _),
    do: {:ok, chain |> String.downcase() |> String.to_existing_atom()}

  def metadata(%Asset{ticker: ticker} = asset, _, _) do
    with {:ok, metadata} <- Assets.load_metadata(asset) do
      {:ok, metadata}
    else
      _ -> {:ok, %{symbol: ticker, decimals: Rujira.Assets.decimals(asset)}}
    end
  end

  def prices(_, b) do
    Rujira.Prices.get(b)
  end

  def quote(%{request: %{to_asset: asset}, expected_amount_out: amount}, _, _) do
    {:ok, %{asset: asset, amount: amount}}
  end
end
