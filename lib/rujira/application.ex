defmodule Rujira.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []
    observers = Application.get_env(:rujira, :observers) || []

    base = [
      {Cluster.Supervisor, [topologies, [name: Rujira.ClusterSupervisor]]},
      RujiraWeb.Telemetry,
      Rujira.Repo,
      {Phoenix.PubSub, name: Rujira.PubSub},
      # Start a worker by calling: Rujira.Worker.start_link(arg)
      # {Rujira.Worker, arg},
      # Start to serve requests, typically the last entry
      RujiraWeb.Endpoint,
      RujiraWeb.Presence,
      {Absinthe.Subscription, RujiraWeb.Endpoint},
      {Finch, name: Rujira.Finch},
      Thornode
    ]

    base =
      if Mix.env() != :test do
        Enum.concat(base, [Rujira.Prices.Coingecko])
      else
        base
      end

    Thornode.Appsignal.attach()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rujira.Supervisor]

    Supervisor.start_link(Enum.concat(base, observers), opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RujiraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
