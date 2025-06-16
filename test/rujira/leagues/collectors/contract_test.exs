defmodule Rujira.Leagues.Collectors.ContractTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Repo

  test "collects fees for leagues from contracts" do
    # 4539686 executes a trade on the ruji - usdt book sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5
    # it should store the tx events in leagues and collect the fees
    # it should update the league genesis season 0

    {:ok, block} = Block.load_block("4539686")
    Rujira.Leagues.Collectors.Contract.handle_new_block(block, nil)

    leaderboard = Rujira.Leagues.leaderboard("genesis", 0, "", :points, :desc) |> Repo.all()

    [
      %{
        address: "sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut",
        points: 91701,
        rank: 1,
        badges: ["trade"],
        rank_previous: 1,
        total_tx: 1
      }
    ] = leaderboard

    # league account should have 1 transaction
    {:ok, account} =
      Rujira.Leagues.account_from_id("genesis/0/sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut")

    %{
      id: "genesis/0/sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut",
      league: "genesis",
      season: 0,
      address: "sthor1t4gsjfs8q8j3mw2e402r8vzrtaslsf5re3ktut",
      points: 91701,
      total_tx: 1,
      rank: 1,
      rank_previous: 1,
      badges: ["trade"],
      transactions: nil
    } = account
  end
end
