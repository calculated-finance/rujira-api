defmodule RujiraWeb.Resolvers.Ventures do
  @moduledoc false

  alias Absinthe.Relay
  alias Rujira.Ventures

  def resolver(_, _, _) do
    with {:ok, keiko} <- Ventures.keiko() do
      {:ok, %{config: keiko}}
    end
  end

  def sales(_, args, _) do
    owner = Map.get(args, :owner)
    status = Map.get(args, :status)

    with {:ok, sales} <- Ventures.load_sales(owner, status) do
      Relay.Connection.from_list(sales, args)
    end
  end

  def sale(_, %{idx: idx}, _), do: Ventures.sale_from_id(idx)

  def validate_token(_, %{token: token_input}, _) do
    token_payload = transform_token_input(token_input)
    Ventures.validate_token(token_payload)
  end

  def validate_tokenomics(_, %{token: token_input, tokenomics: tokenomics_input}, _) do
    token_payload = transform_token_input(token_input)
    transformed_tokenomics = transform_tokenomics_input(tokenomics_input)
    Ventures.validate_tokenomics(token_payload, transformed_tokenomics)
  end

  def validate_venture(_, %{venture: venture_input}, _) do
    pilot_input = venture_input.pilot

    token_payload = transform_token_input(pilot_input.token)
    transformed_tokenomics = transform_tokenomics_input(pilot_input.tokenomics)

    final_pilot_payload =
      pilot_input
      |> Map.put(:token, token_payload)
      |> Map.put(:tokenomics, transformed_tokenomics)

    venture_payload = %{pilot: final_pilot_payload}

    Ventures.validate_venture(venture_payload)
  end

  defp transform_token_input(token_input) do
    if Map.has_key?(token_input, :denom) && !is_nil(token_input.denom) do
      %{exists: %{denom: token_input.denom}}
    else
      create_data = token_input |> Map.drop([:denom])
      %{create: create_data}
    end
  end

  defp transform_tokenomics_input(%{categories: categories} = input) do
    transformed_categories =
      Enum.map(categories, fn category ->
        recipients =
          Enum.map(category.recipients, &transform_recipient/1)

        %{category | recipients: recipients}
      end)

    %{input | categories: transformed_categories}
  end

  defp transform_recipient(%{address: address, amount: amount}) when not is_nil(address) do
    %{send: %{address: address, amount: amount}}
  end

  defp transform_recipient(%{amount: amount}) do
    %{set: %{amount: amount}}
  end
end
