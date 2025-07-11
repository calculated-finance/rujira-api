defmodule Thorchain.Affiliates do
  @moduledoc """
  Parses affiliates and BPS values from a THORChain swap memo.

  Returns a list of `{affiliate, bps_decimal}` tuples, or errors.
  """

  alias Rujira.Repo
  alias Thorchain.Swaps.Affiliate

  def insert_all(affiliates) when is_list(affiliates) and affiliates != [] do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    affiliates_with_timestamps =
      Enum.map(affiliates, fn aff ->
        aff
        |> Map.put_new(:inserted_at, now)
        |> Map.put_new(:updated_at, now)
      end)

    Repo.insert_all(Affiliate, affiliates_with_timestamps, on_conflict: :nothing)
  end

  def insert_all(_), do: :ok

  @doc """
  Parses the affiliate and BPS portion of a THORChain memo.

  ## Returns
    - `{:ok, [{affiliate, bps_decimal}, ...]}`
    - `{:error, :no_affiliate}` if no affiliates found
    - `:error` on malformed input
  """
  @spec get_affiliate(binary()) ::
          :error | {:error, :no_affiliate} | {:ok, [{String.t(), Decimal.t()}]}
  def get_affiliate(memo) do
    parts = String.split(memo, ":")
    parse_affiliate_parts(parts)
  end

  defp parse_affiliate_parts([_a, _b, _c, _d, affiliates_str, bps_str | _]) do
    affiliates = parse_list(affiliates_str)
    bps = parse_list(bps_str)

    cond do
      affiliates == [] or bps == [] ->
        {:error, :no_affiliate}

      length(affiliates) == length(bps) ->
        zip_and_cast(affiliates, bps)

      length(bps) == 1 and length(affiliates) > 1 ->
        zip_and_cast(affiliates, List.duplicate(hd(bps), length(affiliates)))

      true ->
        :error
    end
  end

  defp parse_affiliate_parts(_), do: {:error, :no_affiliate}

  defp parse_list(""), do: []
  defp parse_list(str), do: String.split(str, "/")

  defp zip_and_cast(affiliates, bps) do
    pairs =
      Enum.zip(affiliates, bps)
      |> Enum.map(&cast_affiliate_bps/1)

    if Enum.any?(pairs, &match?(:error, &1)) do
      :error
    else
      {:ok, pairs}
    end
  end

  defp cast_affiliate_bps({aff, bps_str}) do
    case Decimal.cast(bps_str) do
      {:ok, bps_dec} ->
        {aff, Decimal.div(bps_dec, Decimal.new(10_000))}

      _ ->
        :error
    end
  end
end
