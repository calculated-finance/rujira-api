defmodule Rujira.Fin.IndexerTest do
  use Rujira.PublisherCase
  alias Rujira.Fin.Indexer
  alias Rujira.Fixtures.Block

  test "indexing trades - broadcast over candle" do
    # 4539686 executes a trade on the ruji - usdt book sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5
    # it should store the trade
    # price: "mm:0.885348892414736995",
    # side: "quote"
    {:ok, block} = Block.load_block("4539686")
    Indexer.handle_new_block(block, nil)

    trades =
      Rujira.Fin.list_trades("sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5")

    assert length(trades) == 1

    [%Rujira.Fin.Trade{} = trade] = trades
    assert trade.price == Decimal.new("0.885348")
    assert trade.type == "sell"

    # a trade execution should broadcast a candle change
    # 1 trade id + 1 pair update + 12 candles
    messages = collect_publishes()

    assert length(messages) == 14
    [{:published, _, %{id: trade_idx}, _} | rest] = messages

    # Assert that the first message is a trade index starting with "FinTrade:" idx depends on Trade Table sequence
    assert String.starts_with?(trade_idx, Base.encode64("FinTrade:"))

    assert rest ==
             [
               {:published, RujiraWeb.Endpoint,
                %{
                  id:
                    Base.encode64(
                      "FinPair:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5"
                    )
                },
                [
                  node:
                    Base.encode64(
                      "FinPair:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5"
                    )
                ]},
               {:published, RujiraWeb.Endpoint,
                %{
                  id:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1/2025-06-09T11:12:00Z"
                    )
                },
                [
                  node:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1/2025-06-09T11:12:00Z"
                    ),
                  edge:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1"
                    )
                ]},
               {:published, RujiraWeb.Endpoint,
                %{
                  id:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/3/2025-06-09T11:12:00Z"
                    )
                },
                [
                  node:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/3/2025-06-09T11:12:00Z"
                    ),
                  edge:
                    Base.encode64(
                      "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/3"
                    )
                ]},
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/5/2025-06-09T11:10:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/5/2025-06-09T11:10:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/5"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/15/2025-06-09T11:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/15/2025-06-09T11:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/15"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/30/2025-06-09T11:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/30/2025-06-09T11:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/30"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/60/2025-06-09T11:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/60/2025-06-09T11:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/60"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/120/2025-06-09T10:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/120/2025-06-09T10:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/120"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/180/2025-06-09T09:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/180/2025-06-09T09:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/180"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/240/2025-06-09T08:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/240/2025-06-09T08:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/240"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1D/2025-06-09T00:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1D/2025-06-09T00:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1D"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1M/2025-06-01T00:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1M/2025-06-01T00:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/1M"
                     )
                 ]
               },
               {
                 :published,
                 RujiraWeb.Endpoint,
                 %{
                   id:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/12M/2025-01-01T00:00:00Z"
                     )
                 },
                 [
                   node:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/12M/2025-01-01T00:00:00Z"
                     ),
                   edge:
                     Base.encode64(
                       "FinCandle:sthor1uywajy5vddpsvdkcztp92ymlnfwv07tu4stpprwrts4lmc6c9l0sy4s4e5/12M"
                     )
                 ]
               }
             ]
  end
end
