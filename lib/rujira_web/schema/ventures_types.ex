defmodule RujiraWeb.Schema.VenturesTypes do
  @moduledoc """
  Defines GraphQL types for Ventures data in the Rujira API.

  This module contains the type definitions and field resolvers for Ventures
  GraphQL objects, including sales, tokenomics, and related data structures.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Rujira.Assets
  alias Rujira.Keiko.Sale.Pilot, as: PilotSale
  alias Rujira.Keiko.Tokenomics.Send
  alias Rujira.Keiko.Tokenomics.Set
  alias Rujira.Keiko.Tokenomics.Stream
  alias RujiraWeb.Resolvers.Ventures

  object :ventures do
    field :config, :ventures_config

    connection field :sales, node_type: :ventures_sale do
      arg(:owner, :address)
      arg(:status, list_of(non_null(:ventures_sale_status)))
      resolve(&Ventures.sales/3)
    end

    field :validate_token, :ventures_validate_token_response do
      arg(:token, non_null(:ventures_token_input))
      resolve(&Ventures.validate_token/3)
    end

    field :validate_tokenomics, :ventures_validate_token_response do
      arg(:token, non_null(:ventures_token_input))
      arg(:tokenomics, non_null(:ventures_tokenomics_input))
      resolve(&Ventures.validate_tokenomics/3)
    end

    field :validate_venture, :ventures_validate_token_response do
      arg(:venture, non_null(:ventures_configure_input))
      resolve(&Ventures.validate_venture/3)
    end
  end

  connection(node_type: :ventures_sale)

  node object(:ventures_config) do
    field :address, :address
    field :bow, non_null(:venures_config_bow)
    field :fin, non_null(:venures_config_fin)
    field :pilot, non_null(:venures_config_pilot)
    field :streams, non_null(:venures_config_streams)
    field :tokenomics, non_null(:venures_config_tokenomics)
  end

  object :venures_config_bow do
    field :admin, non_null(:address)
    field :code_id, non_null(:integer)
  end

  object :venures_config_fin do
    field :admin, non_null(:address)
    field :code_id, non_null(:integer)
    field :fee_address, non_null(:address)
    field :fee_maker, non_null(:bigint)
    field :fee_taker, non_null(:bigint)
  end

  object :venures_config_pilot do
    field :admin, non_null(:address)
    field :code_id, non_null(:integer)
    field :fee_address, non_null(:address)
    field :fee_maker, non_null(:bigint)
    field :fee_taker, non_null(:bigint)
    field :max_premium, non_null(:integer)

    field :deposit, :balance do
      resolve(fn %{deposit: %{denom: denom, amount: amount}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{asset: asset, amount: amount}}
        end
      end)
    end

    field :bid_assets, non_null(list_of(non_null(:ventures_config_pilot_bid_asset))) do
      resolve(fn %{bid_denoms: bid_denoms}, _, _ -> {:ok, bid_denoms} end)
    end
  end

  object :ventures_config_pilot_bid_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{denom: denom}, _, _ -> Assets.from_denom(denom) end)
    end

    field :min_raise_amount, non_null(:bigint)
  end

  object :venures_config_streams do
    field :cw1_contract_address, non_null(:address)
    field :payroll_factory_contract_address, non_null(:address)
  end

  object :venures_config_tokenomics do
    field :min_liquidity, non_null(:bigint)
  end

  node object(:ventures_sale) do
    field :title, non_null(:string)
    field :description, non_null(:string)
    field :url, non_null(:string)
    field :beneficiary, non_null(:address)
    field :idx, non_null(:string)
    field :owner, non_null(:address)
    field :status, non_null(:ventures_sale_status)
    field :venture, non_null(:ventures_sale_type)
  end

  union :ventures_sale_type do
    types([:ventures_sale_pilot])

    resolve_type(fn
      %PilotSale{}, _ -> :ventures_sale_pilot
    end)
  end

  object :ventures_sale_pilot do
    field :sale, non_null(:pilot_sale)
    field :token, non_null(:ventures_token)
    field :tokenomics, non_null(:ventures_tokenomics)
    field :fin, :address
    field :bow, :address
    field :terms_conditions_accepted, non_null(:boolean)
  end

  object :ventures_token do
    field :admin, :address
    field :asset, non_null(:asset)
  end

  enum :ventures_sale_status do
    value(:configured)
    value(:scheduled)
    value(:in_progress)
    value(:executed)
    value(:retracted)
    value(:completed)
  end

  # Input type for the validate_token query
  input_object :ventures_token_input do
    # Fields for Create case
    field :symbol, :string
    field :name, :string
    field :display, :string
    field :description, :string
    # Optional
    field :denom_admin, :address
    field :png_url, :string
    field :svg_url, :string
    # Optional
    field :uri, :string
    # Optional
    field :uri_hash, :string

    # Field for Exists case
    field :denom, :string
  end

  # Output type for the validate_token query
  object :ventures_validate_token_response do
    field :valid, :boolean
    field :message, :string
  end

  object :ventures_tokenomics do
    field :categories, list_of(:ventures_tokenomics_categories)
  end

  enum :ventures_tokenomics_category_type do
    value(:sale, description: "Sale category type")
    value(:liquidity, description: "Liquidity category type")
    value(:standard, description: "Standard category type")
  end

  input_object :ventures_tokenomics_recipient_input do
    # For :send case
    field :address, :address
    # For both :send and :set case
    field :amount, non_null(:integer)
  end

  input_object :ventures_tokenomics_category_input do
    field :label, non_null(:string)
    field :type, non_null(:ventures_tokenomics_category_type)
    field :recipients, non_null(list_of(non_null(:ventures_tokenomics_recipient_input)))
  end

  input_object :ventures_tokenomics_input do
    field :categories, non_null(list_of(non_null(:ventures_tokenomics_category_input)))
  end

  input_object :pilot_details_input do
    field :title, non_null(:string)
    field :description, non_null(:string)
    field :url, non_null(:string)
    field :beneficiary, non_null(:address)
    field :price, non_null(:integer)
    # datetime?
    field :opens, non_null(:string)
    # datetime?
    field :closes, non_null(:string)
    field :bid_denom, non_null(:string)
    field :bid_threshold, non_null(:string)
    field :max_premium, non_null(:integer)
    field :waiting_period, non_null(:integer)
  end

  input_object :ventures_configure_pilot_input do
    field :terms_conditions_accepted, non_null(:boolean)
    field :token, non_null(:ventures_token_input)
    field :tokenomics, non_null(:ventures_tokenomics_input)
    field :pilot, non_null(:pilot_details_input)
  end

  input_object :ventures_configure_input do
    field :pilot, :ventures_configure_pilot_input
  end

  union :ventures_tokenomics_recipient do
    types([
      :ventures_tokenomics_recipient_set,
      :ventures_tokenomics_recipient_send,
      :ventures_tokenomics_recipient_stream
    ])

    resolve_type(fn
      %Send{}, _ ->
        :ventures_tokenomics_recipient_send

      %Set{}, _ ->
        :ventures_tokenomics_recipient_set

      %Stream{}, _ ->
        :ventures_tokenomics_recipient_stream
    end)
  end

  object :ventures_tokenomics_recipient_set do
    field :amount, non_null(:string)
  end

  object :ventures_tokenomics_recipient_send do
    field :address, :address
    field :amount, non_null(:string)
  end

  object :ventures_tokenomics_recipient_stream do
    field :owner, :address
    field :recipient, :address
    field :title, :string
    field :total, non_null(:bigint)
    field :denom, :string
    field :start_time, :timestamp
    field :schedule, :string
    field :vesting_duration_seconds, non_null(:bigint)
    field :unbonding_duration_seconds, non_null(:bigint)
  end

  object :ventures_tokenomics_categories do
    field :label, non_null(:string)
    field :type, :ventures_tokenomics_category_type
    field :recipients, list_of(:ventures_tokenomics_recipient)
  end
end
