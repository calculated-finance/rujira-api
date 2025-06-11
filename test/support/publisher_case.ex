defmodule Rujira.PublisherCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      setup :verify_on_exit!

      def collect_publishes(acc \\ []) do
        receive do
          {:published, _endpoint, _payload, _topics} = msg ->
            collect_publishes([msg | acc])
        after
          0 ->
            Enum.reverse(acc)
        end
      end

      setup tags do
        # start coingecko gen server
        {:ok, _pid} = Rujira.Prices.Coingecko.start_link([])
        # mock tesla responses
        Rujira.CoingeckoMocks.mock_prices()
        Rujira.DataCase.setup_sandbox(tags)

        stub(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
          send(self(), {:published, endpoint, payload, topics})
          :ok
        end)

        :ok
      end
    end
  end
end
