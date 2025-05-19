defmodule Mix.Tasks.Rujira.Migrate do
  alias Rujira.Deployments
  use Mix.Task

  def run([plan, out]) do
    Mix.Task.run("app.start")
    File.write!(out, Deployments.to_migrate_tx(plan))
  end
end
