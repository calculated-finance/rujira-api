defmodule Rujira.Staking.ListenerTest do
  use Rujira.PublisherCase

  alias Rujira.Fixtures.Block
  alias Rujira.Staking.Listener.Pool

  test "publishes account update" do
    {:ok, block} = Block.load_block("5334888")

    Pool.handle_new_block(block, %{
      address: "sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj",
      receipt_denom: "x/staking-x/ruji"
    })

    messages = collect_publishes()
    assert length(messages) == 4

    assert messages == [
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "StakingStatus:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj"
                  )
              },
              [
                node:
                  Base.encode64(
                    "StakingStatus:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                contract: "sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj"
              }, [staking_account_updated: "*"]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "StakingAccount:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj/"
                  )
              },
              [
                node:
                  Base.encode64(
                    "StakingAccount:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj/"
                  )
              ]},
             {:published, RujiraWeb.Endpoint,
              %{
                id:
                  Base.encode64(
                    "StakingAccount:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj/sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8alysthor1h4eyzp33jx9nxh6dfz7s3jhjn3mkvpehm9mpjg"
                  )
              },
              [
                node:
                  Base.encode64(
                    "StakingAccount:sthor1z42a3wpxl2xfvq967hh9gtwnp3r85l4hvum5lkrz6ku9cpf30fzszf29jj/sthor18afpdapfxxlvxcf95a3rd6p0fsw37mnfqj8alysthor1h4eyzp33jx9nxh6dfz7s3jhjn3mkvpehm9mpjg"
                  )
              ]}
           ]
  end
end
