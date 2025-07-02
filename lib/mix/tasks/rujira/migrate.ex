defmodule Mix.Tasks.Rujira.Migrate do
  @moduledoc """
  Mix task for generating migration transactions.

  This task generates migration transactions based on a provided plan file
  and writes the resulting transaction data to the specified output file.

  ## Usage
      mix rujira.migrate <plan_file> <output_file>
  """
  alias Rujira.Deployments
  use Mix.Task

  def run([out]) do
    Mix.Task.run("app.start")
    File.write!(out, Deployments.to_migrate_tx())
  end
end
