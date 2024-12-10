defmodule Rujira.Merge.Service do
  alias Rujira.Merge.Pool
  alias Rujira.Merge.Account

  @precision 1_000_000_000_000

  @spec get_stats() :: {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def get_stats() do
    with {:ok, pools} <- Rujira.Merge.list_pools(),
         {:ok, stats} <-
           Task.async_stream(pools, &Rujira.Merge.load_pool/1)
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, stats}
    end
  end

  @spec get_rates(list(Pool.t())) :: {:ok, list()}
  def get_rates(pools) do
    with {:ok, pools} <-
           Enum.map(pools, fn pool ->
             total_allocation = Map.get(pool, :merge_supply)
             ruji_allocation = Map.get(pool, :ruji_allocation)
             decay_ends_at = Map.get(pool, :decay_ends_at)
             decay_starts_at = Map.get(pool, :decay_starts_at)
             shares = Map.get(pool.status, :shares)
             size = Map.get(pool.status, :size)

             now = DateTime.utc_now()

             remaining_time = DateTime.diff(decay_ends_at, now, :second)
             duration = DateTime.diff(decay_ends_at, decay_starts_at, :second)

             start_rate = trunc(div(ruji_allocation * @precision, total_allocation))

             current_rate =
               trunc(div(start_rate, @precision) * div(remaining_time * @precision, duration))

             effective_rate = if shares == 0, do: 0, else: trunc(div(size * @precision, shares))

             pool
             |> Map.put(:start_rate, start_rate)
             |> Map.put(:current_rate, current_rate)
             |> Map.put(:effective_rate, effective_rate)
           end)
           |> then(&{:ok, &1}) do
      {:ok, pools}
    end
  end

  @spec get_accounts(String.t()) :: {:ok, list(Account.t())} | {:error, GRPC.RPCError.t()}
  def get_accounts(account) do
    with {:ok, pools} <- Rujira.Merge.list_pools(),
         {:ok, accounts} <-
           Task.async_stream(pools, &Rujira.Merge.load_account(&1, account))
           |> Enum.reduce({:ok, []}, fn
             {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
             {:ok, {:error, error}}, _ -> {:error, error}
             {:error, err}, _ -> {:error, err}
           end) do
      {:ok, accounts}
    end
  end

  def account_stats(account_pools) do
    total_stats =
      Enum.reduce(
        account_pools,
        %{
          total_shares: 0,
          total_merged: 0,
          total_size: 0,
          account_pools: []
        },
        fn account_pool, acc ->
          merged = Map.get(account_pool, :merged)
          shares = Map.get(account_pool, :shares)
          size = Map.get(account_pool, :size)
          ruji_allocation = Map.get(account_pool.pool |> elem(0), :ruji_allocation)
          merge_supply = Map.get(account_pool.pool |> elem(0), :merge_supply)

          start_rate = trunc(ruji_allocation * @precision / merge_supply)

          effective_rate =
            if size == 0, do: 0, else: trunc(start_rate / @precision * size * @precision / shares)

          updated_pool = Map.put(account_pool, :effective_rate, effective_rate)

          %{
            total_merged: acc.total_merged + merged,
            total_shares: acc.total_shares + shares,
            total_size: acc.total_size + size,
            account_pools: [updated_pool | acc.account_pools]
          }
        end
      )

    effective_rate =
      if total_stats.total_size == 0,
        do: 0,
        else: trunc(total_stats.total_size * @precision / total_stats.total_shares)

    {:ok,
     Map.put(
       total_stats,
       :effective_rate,
       effective_rate
     )}
  end
end
