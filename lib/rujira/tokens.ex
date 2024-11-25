defmodule Rujira.Tokens do
  @moduledoc """
  Interfaces for interacting with token denominations
  """

  # Kujira-Native tokens
  def decimals(_), do: 6
  def symbol("ukuji"), do: "KUJI"
  def symbol("factory/kujira1sc6a0347cc5q3k890jj0pf3ylx2s38rh4sza4t/ufuzn"), do: "FUZN"
  def symbol("factory/kujira12cjjeytrqcj25uv349thltcygnp9k0kukpct0e/uwink"), do: "WINK"
  def symbol("factory/kujira1aaudpfr9y23lt9d45hrmskphpdfaq9ajxd3ukh/unstk"), do: "NSTK"
  def symbol("factory/kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq/urkuji"), do: "rKUJI"
end
