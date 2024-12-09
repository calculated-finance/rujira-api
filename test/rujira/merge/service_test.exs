defmodule Rujira.Merge.ServiceTest do
  use ExUnit.Case, async: true

  use Rujira.TestHelpers

  # setup :verify_on_exit!

  describe "test_conn/0" do
    test "connects using the mock", %{channel: channel} do
      # Access the channel set up by TestHelpers
      pool = Rujira.Merge.get_pool(channel, "contract-merge")

      assert pool ==
               {:ok,
                %Rujira.Merge.Pool{
                  address: "contract-merge",
                  merge_denom: "gaia-kuji",
                  merge_supply: 1_000_000_000,
                  ruji_denom: "rune",
                  ruji_allocation: 10_000_000_000,
                  decay_starts_at: ~U[2024-12-05 18:47:10Z],
                  decay_ends_at: ~U[2025-12-04 18:47:10Z],
                  status: :not_loaded
                }}
    end
  end
end
