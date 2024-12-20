defmodule Rujira.Fin.Book do

  defmodule Price do
    defstruct [:price, :total, :side, :value]
  end

  defstruct [:bids, :asks]
end
