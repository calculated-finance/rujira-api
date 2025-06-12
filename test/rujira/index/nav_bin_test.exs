defmodule Rujira.Index.NavBinTest do
  use Rujira.PublisherCase

  alias Rujira.Index
  alias Rujira.Index.NavBin

  test "Periodically try to index the nav price of the vaults based on the resolution" do
    now = DateTime.utc_now(:second)
    NavBin.handle_info(now, "1D")

    # List all indexes
    {:ok, vaults} = Index.list_vaults()

    # Assert that the nav bin was indexed for each vault
    for vault <- vaults do
      assert Index.query_nav_bin_at(vault.address, "1D", now) != nil
    end
  end
end
