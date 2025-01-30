defmodule RujiraWeb.Profiler do
  @moduledoc """
  Gather and report telemetry about an individual field resolution
  """
  @field_start [:absinthe, :resolve, :field, :start]
  @field_stop [:absinthe, :resolve, :field, :stop]

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(resolution, _) do
    case resolution.middleware do
      [
        {Absinthe.Middleware.Telemetry, []},
        {{Absinthe.Resolution, :call}, resolver}
      ] ->
        function = Function.info(resolver)

        name =
          "#{function[:module]}.#{function[:name]}"
          |> String.trim_leading("RujiraWeb.Resolvers.")

        parent = Appsignal.Tracer.current_span()
        Appsignal.Tracer.create_span(name, parent)

        %{
          resolution
          | middleware:
              resolution.middleware ++
                [
                  {{__MODULE__, :on_complete}, []}
                ]
        }

      _ ->
        resolution
    end
  end

  def on_complete(%{state: :resolved} = resolution, _) do
    Appsignal.Tracer.current_span()
    |> Appsignal.Tracer.close_span()

    resolution
  end
end
