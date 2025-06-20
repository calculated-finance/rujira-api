defmodule RujiraWeb.Middleware.InstrumentResolver do
  @behaviour Absinthe.Middleware
  alias Appsignal.{Tracer, Span}

  defmodule CloseSpan do
    @behaviour Absinthe.Middleware
    def call(resolution, _config) do
      case get_private(resolution, :appsignal_span) do
        nil ->
          resolution

        span ->
          Tracer.close_span(span)
          RujiraWeb.Middleware.InstrumentResolver.put_private(resolution, :appsignal_span, nil)
      end
    end

    defp get_private(resolution, key) do
      resolution
      |> Map.get(:private, %{})
      |> Map.get(key)
    end
  end

  @impl Absinthe.Middleware
  def call(resolution, _config) do
    current_span = Tracer.current_span()

    # Create the span
    span =
      "graphql_resolver"
      |> Tracer.create_span(current_span)
      |> Span.set_attribute(
        "appsignal:category",
        "graphql.#{resolution.parent_type.identifier}.#{resolution.definition.name}"
      )

    resolution
    |> put_private(:appsignal_span, span)
    |> append_closing_middleware()
  end

  # Append middleware to close the span after resolution completes
  defp append_closing_middleware(resolution) do
    %{resolution | middleware: resolution.middleware ++ [CloseSpan]}
  end

  # Helper functions for working with resolution private data
  def put_private(resolution, key, value) do
    private_data = Map.get(resolution, :private, %{})
    %{resolution | private: Map.put(private_data, key, value)}
  end
end
