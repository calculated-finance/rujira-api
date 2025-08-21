defmodule Rujira.Calc do
  @moduledoc """
    Rujira.Calc - Automated Strategies
  """

  def manager_address, do: Deployments.get_target(__MODULE__, "calc-manager").address
  def scheduler_address, do: Deployments.get_target(__MODULE__, "calc-scheduler").address
end
