defmodule Rujira.Index.Fixed do
  @moduledoc """
  Parses and manages fixed-weight index allocations and their Net Asset Value (NAV) calculations.
  """
  alias Rujira.Index.Vault
  alias Rujira.Prices

  @doc """
  Given `[denom, weight_str]` and the total number of `shares`, parse out:

    1. `weight`   – integer parsed from `weight_str`
    2. `price`    – fetched via `Prices.fin_price/1`
    3. `balance`  – `shares * weight` (rounded → integer)
    4. `value`    – `balance * price` (rounded → integer)

  Returns either `{:ok, %Vault.Allocation{…}}` or `{:error, {:invalid_allocation, denom}}`.
  """
  def parse_allocation([denom, weight_str], shares) do
    with {weight, ""} <- Integer.parse(weight_str),
         {:ok, %{current: price}} <- Prices.fin_price(denom) do
      balance =
        shares
        |> Decimal.mult(weight)
        |> Decimal.round(0, :floor)
        |> Decimal.to_integer()

      value =
        balance
        |> Decimal.mult(price)
        |> Decimal.round()
        |> Decimal.to_integer()

      {:ok,
       %Vault.Allocation{
         denom: denom,
         target_weight: weight,
         balance: balance,
         value: value,
         price: price
       }}
    else
      _ -> {:error, {:invalid_allocation, denom}}
    end
  end

  # Parses each `[denom, weight_str]` in parallel, returning
  # {:ok, list_of_allocations} or the first error encountered.
  def parse_allocations(list, shares) do
    list
    |> Rujira.Enum.reduce_async_while_ok(fn item -> parse_allocation(item, shares) end,
      timeout: 20_000
    )
  end

  def assign_current_weights(allocs) do
    # 1. Compute weighted values = price * target_weight, and accumulate total.
    {weighted_values, total} =
      allocs
      |> Enum.map_reduce(Decimal.new(0), fn %{price: price, target_weight: w}, acc ->
        wv = Decimal.mult(price, w)
        {wv, Decimal.add(acc, wv)}
      end)

    # 2. If total == 0, assign 0 to every current_weight.
    if Decimal.equal?(total, 0) do
      Enum.map(allocs, &Map.put(&1, :current_weight, Decimal.new(0)))
    else
      # 3. Compute initial weights = each (wv / total).
      initial_weights =
        Enum.map(weighted_values, fn wv -> Decimal.div(wv, total) end)

      # 4. Correct rounding error by forcing the last element so sum == 1
      sum_except_last =
        initial_weights
        |> List.delete_at(-1)
        |> Enum.reduce(Decimal.new(0), &Decimal.add/2)

      correction = Decimal.sub(Decimal.new(1), sum_except_last)
      corrected_weights = List.replace_at(initial_weights, -1, correction)

      # 5. Zip allocations with their corrected weights
      Enum.zip_with(allocs, corrected_weights, fn alloc, w ->
        Map.put(alloc, :current_weight, w)
      end)
    end
  end

  @doc """
  Builds a `%Vault{}` struct from a contract `address` and config map containing
  `"fee_collector"` and `"quote_denom"`.
  """
  def from_config(address, %{"fee_collector" => fee_collector, "quote_denom" => denom}) do
    share_denom = "x/nami-index-fixed-#{address}-rcpt"

    {:ok,
     %Vault{
       id: address,
       address: address,
       module: __MODULE__,
       config: %Vault.Config{quote_denom: denom, fee_collector: fee_collector},
       share_denom: share_denom,
       status: :not_loaded,
       fees: :not_loaded
     }}
  end

  def init_msg(msg), do: msg
  def migrate_msg(_from, _to, _), do: %{}
  def init_label(_, %{"receipt" => %{"symbol" => symbol}}), do: "nami-index:#{symbol}:fixed"
end
