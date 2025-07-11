defmodule Rujira.PublisherCase do
  @moduledoc false

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

      def wait_for_publishes(expected_count, timeout \\ 500) do
        start = System.monotonic_time(:millisecond)
        do_wait_for_publishes(expected_count, [], start, timeout)
      end

      defp do_wait_for_publishes(expected_count, acc, start, timeout) do
        acc = acc ++ collect_publishes()

        cond do
          length(acc) >= expected_count ->
            Enum.take(acc, expected_count)

          System.monotonic_time(:millisecond) - start > timeout ->
            flunk(
              "Did not receive #{expected_count} publishes within #{timeout}ms. Got #{length(acc)}: #{inspect(acc)}"
            )

          true ->
            Process.sleep(10)
            do_wait_for_publishes(expected_count, acc, start, timeout)
        end
      end

      setup tags do
        # mock tesla responses
        Rujira.CoingeckoMocks.mock_prices()
        Rujira.DataCase.setup_sandbox(tags)

        test_pid = self()

        stub(Rujira.Events.PublisherMock, :publish, fn endpoint, payload, topics ->
          send(test_pid, {:published, endpoint, payload, topics})
          :ok
        end)

        :ok
      end
    end
  end
end
