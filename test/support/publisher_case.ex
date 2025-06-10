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

      setup do
        stub(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
          send(self(), {:published, endpoint, payload, topics})
          :ok
        end)

        :ok
      end
    end
  end
end
