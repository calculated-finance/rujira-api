defmodule RujiraWeb.Schema.VenturesTypes do
  alias Rujira.Ventures.Pilot
  alias Rujira.Assets
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  object :ventures do
    field :config, :ventures_config

    connection field :sales, node_type: :ventures_sale do
      resolve(&RujiraWeb.Resolvers.Ventures.sales/3)
    end

    connection field :sales_by_owner, node_type: :ventures_sale do
      arg(:owner, non_null(:address))
      resolve(&RujiraWeb.Resolvers.Ventures.sales_by_owner/3)
    end

    connection field :sales_by_status, node_type: :ventures_sale do
      arg(:status, non_null(:ventures_sale_status))
      resolve(&RujiraWeb.Resolvers.Ventures.sales_by_status/3)
    end

    field :sale_by_idx, :ventures_sale do
      arg(:idx, non_null(:string))
      resolve(&RujiraWeb.Resolvers.Ventures.sale_by_idx/3)
    end

    field :validate_token, :ventures_validate_token_response do
      arg(:token, non_null(:ventures_token_input))
      resolve(&RujiraWeb.Resolvers.Ventures.validate_token/3)
    end

    field :validate_tokenomics, :ventures_validate_token_response do
      arg(:token, non_null(:ventures_token_input))
      arg(:tokenomics, non_null(:ventures_tokenomics_input))
      resolve(&RujiraWeb.Resolvers.Ventures.validate_tokenomics/3)
    end

    field :validate_venture, :ventures_validate_token_response do
      arg(:venture, non_null(:ventures_configure_input))
      resolve(&RujiraWeb.Resolvers.Ventures.validate_venture/3)
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

    field :deposit, non_null(:balance) do
      resolve(fn %{deposit: %{denom: denom, amount: amount}}, _, _ ->
        with {:ok, asset} <- Assets.from_denom(denom) do
          {:ok, %{asset: asset, amount: amount}}
        end
      end)
    end

    field :bid_assets, non_null(list_of(non_null(:ventures_config_pilot_bid_asset))) do
      resolve(fn %{bid_denoms: bid_assets}, _, _ -> {:ok, bid_assets} end)
    end
  end

  object :ventures_config_pilot_bid_asset do
    field :asset, non_null(:asset) do
      resolve(fn %{denom: denom}, _, _ ->
        Assets.from_denom(denom)
      end)
    end

    field :min_raise_amount, non_null(:bigint)
  end

  object :venures_config_streams do
    field :admin, non_null(:address)
    field :code_id, non_null(:integer)
  end

  object :venures_config_tokenomics do
    field :min_liquidity, non_null(:bigint)
  end

  union :ventures_sale do
    types([:ventures_sale_pilot, :ventures_sale_bond])

    resolve_type(fn
      %Pilot{}, _ -> :ventures_sale_pilot
      %{}, _ -> :ventures_sale_bond
    end)
  end

  object :ventures_sale_pilot do
    field :idx, non_null(:string)
    field :deposit, :asset
    field :terms_conditions_accepted, non_null(:boolean)
    field :token, non_null(:ventures_token)
    field :tokenomics, non_null(:ventures_tokenomics)
    field :pilot, :address
    field :fin, :address
    field :bow, :address
    field :owner, non_null(:address)
    field :status, non_null(:ventures_sale_status)
  end

  object :ventures_sale_bond do
    field :address, non_null(:address)
  end

  # union :venture_configure do
  #   types([:pilot_config])

  #   resolve_type(fn
  #     %{terms_conditions_accepted: _, token: _, tokenomics: _, pilot: _} -> :pilot_config
  #   end)
  # end

  # object :pilot_config do
  #   field :terms_conditions_accepted, non_null(:boolean)
  #   field :token, non_null(:token)
  #   field :tokenomics, non_null(:tokenomics)
  #   field :pilot, non_null(:pilot)
  # end

  # object :bonds_venture do
  # end

  # enum :venture_type do
  #   value(:pilot, as: 1)
  # end

  enum :ventures_sale_status do
    value(:configured)
    value(:scheduled)
    value(:in_progress)
    value(:executed)
    value(:retracted)
    value(:completed)
  end

  # object :venture do
  #   field :idx, non_null(:string)
  #   field :owner, non_null(:address)
  #   field :status, non_null(:venture_status)
  #   field :venture_type, non_null(:venture_type)
  #   field :venture, non_null(:ventures)
  # end

  # object :coin do
  #   field :denom, non_null(:string)
  #   field :amount, non_null(:bigint)
  # end

  # union :token do
  #   types([:token_create, :token_exists])

  #   resolve_type(fn
  #     %{denom: _}, _ -> :token_exists
  #     %{symbol: _, name: _}, _ -> :token_create
  #   end)
  # end

  object :ventures_token do
    field :symbol, non_null(:string)
    field :name, non_null(:string)
    field :display, non_null(:string)
    field :description, non_null(:string)
    field :denom_admin, :address
    field :png_url, non_null(:string)
    field :svg_url, non_null(:string)
    field :uri, :string
    field :uri_hash, :string
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

  # object :token_exists do
  #   field :denom, non_null(:string)
  # end

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
    # , :ventures_tokenomics_recipient_stream])
    types([:ventures_tokenomics_recipient_set, :ventures_tokenomics_recipient_send])

    resolve_type(fn
      %{amount: _, address: _}, _ ->
        :ventures_tokenomics_recipient_send

      %{amount: _}, _ ->
        :ventures_tokenomics_recipient_set
        # %{recipients: _, schedule: _}, _ -> :ventures_tokenomics_recipient_stream
    end)
  end

  object :ventures_tokenomics_recipient_set do
    field :amount, non_null(:integer)
  end

  object :ventures_tokenomics_recipient_send do
    field :address, :address
    field :amount, non_null(:integer)
  end

  # object :ventures_tokenomics_recipient_stream do
  #   field :recipients, list_of(:ventures_stream_recipient)
  #   field :schedule, non_null(:ventures_schedule)
  # end

  # object :ventures_stream_recipient do
  #   field :address, non_null(:address)
  #   field :percentage, non_null(:integer)
  # end

  object :ventures_tokenomics_categories do
    field :label, non_null(:string)
    field :type, :ventures_tokenomics_category_type
    field :recipients, list_of(:ventures_tokenomics_recipient)
  end

  # object :tokenomics_config do
  #   field :minimum_liquidity_one_side, non_null(:decimal)
  #   field :default_lp_vest_cliff, non_null(:integer)
  #   field :default_lp_vest_duration, non_null(:integer)
  # end

  # object :pilot do
  #   field :title, non_null(:string)
  #   field :description, non_null(:string)
  #   field :url, non_null(:string)

  #   field :beneficiary, non_null(:address),
  #     description: "The address that the raise will be sent to"

  #   field :price, non_null(:decimal), description: "Base price of the token at sale"
  #   field :opens, non_null(:timestamp), description: "The time after which the sale takes orders"

  #   field :closes, non_null(:timestamp),
  #     description: "The time after which the sale can be executed"

  #   field :bid_denom, non_null(:string),
  #     description: "The raise token, that the price is quoted in"

  #   field :bid_threshold, non_null(:string),
  #     description: "The threshold under which bids are automatically activated when placed"

  #   field :max_premium, non_null(:integer),
  #     description: "The maximum premium to be used in the sale as a percentage"

  #   field :waiting_period, non_null(:integer),
  #     description: "The amount of time in seconds that a bid must wait until it can be activated"
  # end

  # union :ventures_schedule do
  #   types([:ventures_continuous_schedule, :ventures_fixed_schedule])

  #   resolve_type(fn
  #     %{period: _}, _ -> :ventures_continuous_schedule
  #     %{ends: _}, _ -> :ventures_fixed_schedule
  #   end)
  # end

  # object :ventures_continuous_schedule do
  #   field :starts, non_null(:timestamp)
  #   field :amount, list_of(:balance) # coin
  #   field :period, non_null(:integer)
  # end

  # object :ventures_fixed_schedule do
  #   field :starts, non_null(:timestamp)
  #   field :ends, non_null(:timestamp)
  #   field :amount, list_of(:balance) # coin
  # end

  # object :pool_response do
  #   field :premium, non_null(:integer)
  #   field :epoch, non_null(:integer)
  #   field :price, non_null(:decimal)
  #   field :total, non_null(:string)
  # end

  # object :pools_response do
  #   field :pools, list_of(:pool_response)
  # end

  # object :pilot_info do
  #   field :pilot, non_null(:pilot)
  #   field :deposit, :coin
  #   field :contract_address, :address
  #   field :raise_amount, :string
  #   field :fee_amount, :string
  #   field :bid_pools_snapshot, :pools_response
  # end

  # object :fin_info do
  #   field :contract_address, non_null(:address)
  # end

  # object :bow_info do
  #   field :contract_address, non_null(:address)
  # end

  # object :streams_info do
  #   field :contract_address, non_null(:address)
  #   field :recipient, non_null(:address)
  # end
end
