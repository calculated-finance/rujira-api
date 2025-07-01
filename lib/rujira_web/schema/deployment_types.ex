defmodule RujiraWeb.Schema.DeploymentTypes do
  @moduledoc """
  Defines GraphQL types for the current deplyment in the Rujira API.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  @desc "The currently configured deployment for all contracts"
  object :deployment do
    field :network, non_null(:string)
    field :targets, non_null(list_of(non_null(:deployment_target)))
  end

  @desc "An individual deplyoment target for a contract"
  node object(:deployment_target) do
    field :address, non_null(:address)
    field :creator, non_null(:address)
    field :code_id, non_null(:integer)
    field :salt, non_null(:string)
    field :admin, :address
    field :protocol, non_null(:string)
    field :module, non_null(:string)
    field :config, non_null(:string)
    field :contract, :contract_info
    field :status, non_null(:deployment_target_status)
  end

  enum :deployment_target_status do
    value(:preview)
    value(:live)
  end
end
