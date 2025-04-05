defmodule Rujira.Denoms do
  @moduledoc """
  Interfaces for interacting with Cosmos SDK x/bank token denominations
  """

  # Cosmos assets are truncated or padded to 8 decimals in Bifrost
  # https://gitlab.com/thorchain/thornode/-/blob/develop/bifrost/pkg/chainclients/gaia/util.go#L82-89
  def decimals("gaia-" <> _), do: 8
  def decimals("rune"), do: 8
  # Kujira-Native tokens
  def decimals(_), do: 6
  def symbol("ruji"), do: "RUJI"
  def symbol("rune"), do: "RUNE"
  def symbol("ukuji"), do: "KUJI"
  def symbol("factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn"), do: "FUZN"
  def symbol("factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink"), do: "WINK"
  def symbol("factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk"), do: "NSTK"
  def symbol("factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji"), do: "RKUJI"

  def symbol(str) do
    # TODO: suport more delimiters
    [_, v | _] = String.split(str, [".", "-"])
    [sym | _] = String.split(v, "-")
    String.upcase(sym)
  end
end
