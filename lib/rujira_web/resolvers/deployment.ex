defmodule RujiraWeb.Resolvers.Deployment do
  @moduledoc """
  Handles GraphQL resolution for deployment-related queries.
  """
  alias Rujira.Deployments

  def resolver(_, _, _) do
    {:ok,
     %{
       version: Deployments.version(),
       targets:
         Deployments.list_all_targets()
         |> Enum.map(fn
           %{config: nil} = target ->
             target

           %{config: config} = target ->
             %{target | config: Jason.encode!(config)}
         end)
     }}
  end
end
