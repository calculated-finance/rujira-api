defmodule RujiraWeb.Resolvers.Ventures do
  alias Rujira.Ventures
  alias Absinthe.Resolution.Helpers

  def resolver(_, _, _) do
    with {:ok, keiko} <- Ventures.keiko() do
      {:ok, %{config: keiko}}
    end
  end

  def sales(_, _, _) do
    with {:ok, sales} <- Ventures.sales() do
      {:ok,
       %{
         page_info: %{
           start_cursor: <<>>,
           end_cursor: <<>>,
           has_previous_page: false,
           has_next_page: false
         },
         edges: sales
       }}
    end
  end
end
