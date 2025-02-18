defmodule RujiraWeb.Resolvers.Bank do
  alias Rujira.Assets

  def total_supply(_, _, _) do
    with {:ok, supplies} <- Rujira.Bank.total_supply() do
      Enum.reduce(supplies, {:ok, []}, fn
        _, {:error, err} ->
          {:error, err}

        {k, v}, {:ok, agg} ->
          case Assets.from_denom(k) do
            {:ok, asset} -> {:ok, [%{asset: asset, amount: v} | agg]}
            err -> err
          end
      end)
    end
  end
end
