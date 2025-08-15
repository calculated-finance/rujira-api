defmodule Thornode.Appsignal do
  require Logger

  @tracer Application.compile_env(:appsignal, :appsignal_tracer, Appsignal.Tracer)
  @span Application.compile_env(:appsignal, :appsignal_span, Appsignal.Span)

  @moduledoc false

  def attach do
    handlers = %{
      [:grpc, :client, :rpc, :start] => &__MODULE__.grpc_request_start/4,
      [:grpc, :client, :rpc, :stop] => &__MODULE__.grpc_request_stop/4,
      [:grpc, :client, :rpc, :exception] => &__MODULE__.grpc_request_stop/4
    }

    for {event, fun} <- handlers do
      case :telemetry.attach({__MODULE__, event}, event, fun, :ok) do
        :ok ->
          _ =
            Appsignal.IntegrationLogger.debug("Thornode.Appsignal attached to #{inspect(event)}")

          :ok

        {:error, _} = error ->
          Logger.warning(
            "Thornode.Appsignal not attached to #{inspect(event)}: #{inspect(error)}"
          )

          error
      end
    end

    :telemetry.attach_many(
      "ecto-queue-logger",
      [[:rujira, :repo, :query]],
      fn _event, meas, meta, _ ->
        Logger.info(fn ->
          "Ecto queue=#{System.convert_time_unit(meas[:queue_time], :native, :millisecond)} decode=#{System.convert_time_unit(meas[:decode_time], :native, :millisecond)} query=#{System.convert_time_unit(meas[:query_time], :native, :millisecond)} idle=#{System.convert_time_unit(meas[:idle_time], :native, :millisecond)} query=#{String.slice(meta.query, 0, 100)}..."
        end)
      end,
      nil
    )
  end

  def grpc_request_start(
        _event,
        _measurements,
        %{stream: %{path: path}},
        _config
      ) do
    do_grpc_request_start(@tracer.current_span(), path)
  end

  defp do_grpc_request_start(nil, _request), do: nil

  defp do_grpc_request_start(parent, path) do
    "grpc_request"
    |> @tracer.create_span(parent)
    |> @span.set_name(path)
    |> @span.set_attribute("appsignal:category", "request.grpc")
  end

  def grpc_request_stop(_event, _measurements, %{request: _request}, _config) do
    @tracer.close_span(@tracer.current_span())
  end

  def grpc_request_stop(_event, _measurements, _metadata, _config) do
    nil
  end
end
