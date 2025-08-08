defmodule Rujira.Keiko.Tokenomics do
  @moduledoc """
  This module provides the type definition and parsing logic for a Tokenomics design used by the Keiko deployment orchestrator.
  """

  defmodule Category do
    @moduledoc false
    alias Rujira.Keiko.Tokenomics.Send
    alias Rujira.Keiko.Tokenomics.Set
    alias Rujira.Keiko.Tokenomics.Stream

    defstruct [:type, :label, :recipients]

    @type type :: :standard | :sale | :liquidity
    @type recipient :: Send.t() | Set.t() | Stream.t()

    @type t :: %__MODULE__{
            type: type(),
            label: String.t(),
            recipients: list(recipient())
          }

    def from_query(%{
          "category_type" => category_type,
          "label" => label,
          "recipients" => recipients
        }) do
      with {:ok, recipients} <-
             Rujira.Enum.reduce_while_ok(recipients, [], &parse_recipient/1),
           recipients <- List.flatten(recipients),
           {:ok, type} <- parse_type(category_type) do
        {:ok,
         %__MODULE__{
           type: type,
           label: label,
           recipients: recipients
         }}
      end
    end

    defp parse_recipient(%{"send" => send}), do: Send.from_query(send)
    defp parse_recipient(%{"set" => set}), do: Set.from_query(set)

    defp parse_recipient(%{"stream" => %{"streams" => streams}}),
      do: Rujira.Enum.reduce_while_ok(streams, [], &Stream.from_query/1)

    defp parse_recipient(_), do: {:error, :unknown_recipient_type}

    defp parse_type("standard"), do: {:ok, :standard}
    defp parse_type("sale"), do: {:ok, :sale}
    defp parse_type("liquidity"), do: {:ok, :liquidity}
    defp parse_type(_), do: {:error, :invalid_type}
  end

  defstruct [:categories]

  @type t :: %__MODULE__{
          categories: list(Category.t())
        }

  def from_query(%{
        "categories" => categories
      }) do
    with {:ok, categories} <-
           Rujira.Enum.reduce_while_ok(categories, [], &Category.from_query/1) do
      {:ok, %__MODULE__{categories: categories}}
    end
  end

  def get_sale_amount(tokenomics) do
    tokenomics.categories
    |> Enum.find(fn category -> category.type == :sale end)
    |> case do
      nil -> {:error, :sale_category_not_found}
      sale_category -> {:ok, Enum.at(sale_category.recipients, 0).amount}
    end
  end
end
