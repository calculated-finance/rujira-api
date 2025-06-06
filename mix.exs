defmodule Rujira.MixProject do
  use Mix.Project

  def project do
    [
      app: :rujira,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Rujira.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe_phoenix, "~> 2.0"},
      {:absinthe_plug, "1.5.8"},
      {:absinthe_relay, "~> 1.5"},
      {:absinthe, "~> 1.7"},
      {:appsignal, "~> 2.8"},
      {:bandit, "~> 1.5"},
      {:cors_plug, "~> 3.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.10"},
      {:ethereumex, "~> 0.10"},
      {:ex_abi, "~> 0.5"},
      {:ex_keccak, "~> 0.7.6"},
      {:finch, "~> 0.19.0"},
      {:google_protos, "~> 0.4"},
      {:grpc, "~> 0.9"},
      {:jason, "~> 1.2"},
      {:memoize, "~> 1.4"},
      {:mox, "~> 1.2"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:poolboy, "~> 1.5.1"},
      {:postgrex, ">= 0.0.0"},
      {:protobuf, "~> 0.13.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tesla, "~> 1.11"},
      {:timex, "~> 3.7.11"},
      {:websockex, "~> 0.4.3"},
      {:yaml_elixir, "~> 2.11.0"},
      {:libcluster, "~> 3.3.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
