defmodule Rujira.Fin.Book do

  defmodule Price do
    defstruct [:price, :total, :side]
  end

  defstruct [:bids, :asks]
end
