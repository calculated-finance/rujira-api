defmodule RujiraWeb.Resolvers.Ventures do
  alias Rujira.Ventures
  alias Absinthe.Relay

  def resolver(_, _, _) do
    with {:ok, keiko} <- Ventures.keiko() do
      {:ok, %{config: keiko}}
    end
  end

  def sales(_, _, _) do
    with {:ok, sales} <- Ventures.sales() do
      Relay.Connection.from_list(sales, %{first: 100})
    end
  end

  def sales_by_owner(_, %{owner: owner}, _) do
    with {:ok, sales} <- Ventures.sales_by_owner(owner) do
      Relay.Connection.from_list(sales, %{first: 100})
    end
  end

  def sales_by_status(_, %{status: status}, _) do
    with {:ok, sales} <- Ventures.sales_by_status(status) do
      Relay.Connection.from_list(sales, %{first: 100})
    end
  end

  def sale_by_idx(_, %{idx: idx}, _) do
    Ventures.sale_by_idx(idx)
  end

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

  defp transform_tokenomics_input(tokenomics_input) do
    update_in(tokenomics_input[:categories], fn categories ->
      Enum.map(categories, fn category ->
        update_in(category[:recipients], fn recipients ->
          Enum.map(recipients, fn recipient ->
            if Map.has_key?(recipient, :address) && !is_nil(recipient.address) do
              %{send: %{address: recipient.address, amount: recipient.amount}}
            else
              %{set: %{amount: recipient.amount}}
            end
          end)
        end)
      end)
    end)
  end
end
