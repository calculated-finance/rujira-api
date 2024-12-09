defmodule Rujira.Merge.ServiceTest do
  use ExUnit.Case, async: true

  use Rujira.TestHelpers
  alias Rujira.Merge.Pool

  # setup :verify_on_exit!

  describe "get_rates/0" do
    test "get_rates", %{channel: channel} do
      # list all the pool
      {:ok, pool_list} = Rujira.Merge.list_pools(channel)

      # load all the pools
      {:ok, loaded_pools} =
        Task.async_stream(pool_list, &Rujira.Merge.load_pool(channel, &1))
        |> Enum.reduce({:ok, []}, fn
          {:ok, {:ok, pool}}, {:ok, acc} -> {:ok, [pool | acc]}
          {:ok, {:error, error}}, _ -> {:error, error}
          {:error, err}, _ -> {:error, err}
        end)

      # get the rates of the pools
      {:ok, pool_with_rates} = Rujira.Merge.Service.get_rates(loaded_pools)

      assert pool_with_rates ==
               [
                 %{
                   status: %Rujira.Merge.Pool.Status{merged: 1, shares: 1, size: 2},
                   address: "contract-merge-1",
                   __struct__: Rujira.Merge.Pool,
                   merge_denom: "gaia-kuji",
                   merge_supply: 1_000_000_000,
                   ruji_denom: "rune",
                   ruji_allocation: 10_000_000_000,
                   decay_starts_at: ~U[2024-12-05 18:47:10Z],
                   decay_ends_at: ~U[2025-12-04 18:47:10Z],
                   start_rate: 10_000_000_000_000,
                   current_rate: 9_892_872_405_370,
                   effective_rate: 2_000_000_000_000
                 },
                 %{
                   status: %Rujira.Merge.Pool.Status{merged: 2, shares: 3, size: 4},
                   address: "contract-merge-2",
                   __struct__: Rujira.Merge.Pool,
                   merge_denom: "gaia-kuji",
                   merge_supply: 2_000_000_000,
                   ruji_denom: "ruji",
                   ruji_allocation: 30_000_000_000,
                   decay_starts_at: ~U[2024-12-05 18:47:10Z],
                   decay_ends_at: ~U[2025-12-04 18:47:10Z],
                   start_rate: 15_000_000_000_000,
                   current_rate: 14_839_308_608_055,
                   effective_rate: 1_333_333_333_333
                 }
               ]
    end
  end
end
