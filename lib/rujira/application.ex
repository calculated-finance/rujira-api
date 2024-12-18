defmodule Rujira.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
require Logger

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RujiraWeb.Telemetry,
      Rujira.Repo,
      {DNSCluster, query: Application.get_env(:rujira, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Rujira.PubSub},
      # Start a worker by calling: Rujira.Worker.start_link(arg)
      # {Rujira.Worker, arg},
      # Start to serve requests, typically the last entry
      RujiraWeb.Endpoint,
      {Finch, name: Rujira.Finch},
      {Rujira.Invalidator, pubsub: Rujira.PubSub},
      {Thorchain.Node, websocket: "wss://rpc-kujira-testnet.starsquid.io", subscriptions: ["tm.event='NewBlock'"]},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rujira.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RujiraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
