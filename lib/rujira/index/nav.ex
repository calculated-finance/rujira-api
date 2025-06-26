defmodule Rujira.Index.Nav do
  @moduledoc """
  Parses and manages Net Asset Value (NAV) calculations and allocations for index vaults.
  """
  alias Rujira.Assets
  alias Rujira.Index.Vault

  @doc """
  Parse a single allocation row of the form:
    %{"denom" => denom, "balance" => balance_str, "weight" => weight_str}

  Returns `{:ok, %Vault.Allocation{…}}` or `{:error, {:invalid_allocation, denom}}`.
  """
  def parse_allocation(%{"denom" => denom, "balance" => balance_str, "weight" => weight_str}) do
    with {balance, ""} <- Integer.parse(balance_str),
         {weight, ""} <- Decimal.parse(weight_str),
         {:ok, asset} <- Assets.from_denom(denom),
         {:ok, price} <- Thorchain.oracle_price(asset.id) do
      value =
        balance
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      {:ok,
       %Vault.Allocation{
         denom: denom,
         balance: balance,
         value: value,
         target_weight: weight,
         price: price
       }}
    else
      _ -> {:error, {:invalid_allocation, denom}}
    end
  end

  @doc """
  Given a list of `%Vault.Allocation{}` structs, attach a `:current_weight` field to each,
  computed as `value / sum_of_all_values` (Decimal). If total is zero, all weights are 0.
  """
  def add_current_weights(allocs) do
    total_value =
      allocs
      |> Enum.reduce(0, fn %{value: v}, acc -> acc + v end)

    if total_value == 0 do
      Enum.map(allocs, &Map.put(&1, :current_weight, Decimal.new(0)))
    else
      total_decimal = Decimal.new(total_value)

      Enum.map(allocs, fn alloc ->
        weight =
          alloc.value
          |> Decimal.new()
          |> Decimal.div(total_decimal)

        Map.put(alloc, :current_weight, weight)
      end)
    end
  end

  def parse_allocations(raw_allocs) do
    raw_allocs
    |> Rujira.Enum.reduce_async_while_ok(&parse_allocation/1, timeout: 20_000)
  end

  @doc """
  Construct a `%Vault{}` given a contract `address` and a config map with
  `"fee_collector"` and `"quote_denom"`.
  """
  def from_config(address, %{"fee_collector" => fee_collector, "quote_denom" => denom}) do
    share_denom = "x/nami-index-nav-#{address}-rcpt"

    {:ok,
     %Vault{
       id: address,
       address: address,
       module: __MODULE__,
       config: %Vault.Config{quote_denom: denom, fee_collector: fee_collector},
       share_denom: share_denom,
       status: :not_loaded,
       fees: :not_loaded,
       deployment_status: :live
     }}
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, %{"receipt" => %{"symbol" => symbol}}), do: "nami-index:#{symbol}:nav"
end
