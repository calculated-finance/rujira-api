defmodule Thorchain.Grpc.Client do
  @moduledoc """
  GRPC client with parallel connection attempts to all servers using Poolboy workers.
  """
  @timeout 500

  def connection do
    :poolboy.transaction(:grpc_pool, &GenServer.call(&1, :channel, @timeout))
  end

  def stub(stub_fn, req) do
    :poolboy.transaction(:grpc_pool, fn worker_pid ->
      try do
        with {:ok, channel} <- GenServer.call(worker_pid, :channel, @timeout) do
          stub_fn.(channel, req)
        end
      catch
        :error, _ ->
          reconnect_and_retry(worker_pid, stub_fn, req)
      end
    end)
  end

  defp reconnect_and_retry(worker_pid, stub_fn, req) do
    with {:ok, _} <- GenServer.call(worker_pid, :reconnect, @timeout) do
      stub(stub_fn, req)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
