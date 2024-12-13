defmodule Rujira.Grpc.Client do
  @moduledoc """
  GRPC client with parallel connection attempts to all servers using Poolboy workers.
  """
  use Appsignal.Instrumentation.Decorators

  @timeout 500

  def connection do
    :poolboy.transaction(:grpc_pool, &GenServer.call(&1, :channel, @timeout))
  end

  @decorate transaction_event()
  def stub(stub_fn, req) do
    :poolboy.transaction(:grpc_pool, fn worker_pid ->
      try do
        clean_function_name =
          stub_fn
          |> inspect()
          |> String.trim_leading("&")
          |> String.replace(".", "_")
          |> String.replace("/", "_")

        with {:ok, channel} <- GenServer.call(worker_pid, :channel, @timeout) do
          Appsignal.instrument("#{clean_function_name}", fn ->
            stub_fn.(channel, req)
          end)
        end
      catch
        :error, _ ->
          reconnect_and_retry(worker_pid, stub_fn, req)
      end
    end)
  end

  defp reconnect_and_retry(worker_pid, stub_fn, req) do
    with {:ok, new_channel} <- GenServer.call(worker_pid, :reconnect, @timeout) do
      stub_fn.(new_channel, req)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
