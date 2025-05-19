defmodule Rujira.Deployments.Target do
  defstruct [
    :id,
    :address,
    :creator,
    :code_id,
    :salt,
    :admin,
    :protocol,
    :module,
    :config,
    :contract
  ]
end
