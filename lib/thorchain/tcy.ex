defmodule Thorchain.Tcy do
  use Memoize

  @claims Path.join(:code.priv_dir(:rujira), "data/thorchain_tcy_claims.json")

  defmemo claim(asset, address) do
    with %{"tcy_claim" => amount} <-
           Enum.find(
             claims(),
             &(&1["asset"] == String.downcase(asset) and &1["address"] == address)
           ) do
      {:ok, amount}
    else
      _ ->
        {:error, :not_found}
    end
  end

  defmemo claims() do
    @claims
    |> File.read!()
    |> Jason.decode!()
  end
end
