defmodule Thorchain.Types.QueryPoolRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string
  field :height, 2, type: :string
end

defmodule Thorchain.Types.QueryPoolResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string, deprecated: false
  field :short_code, 2, type: :string, json_name: "shortCode"
  field :status, 3, type: :string, deprecated: false
  field :decimals, 4, type: :int64

  field :pending_inbound_asset, 5,
    type: :string,
    json_name: "pendingInboundAsset",
    deprecated: false

  field :pending_inbound_rune, 6,
    type: :string,
    json_name: "pendingInboundRune",
    deprecated: false

  field :balance_asset, 7, type: :string, json_name: "balanceAsset", deprecated: false
  field :balance_rune, 8, type: :string, json_name: "balanceRune", deprecated: false
  field :asset_tor_price, 9, type: :string, json_name: "assetTorPrice", deprecated: false
  field :pool_units, 10, type: :string, json_name: "poolUnits", deprecated: false
  field :LP_units, 11, type: :string, json_name: "LPUnits", deprecated: false
  field :synth_units, 12, type: :string, json_name: "synthUnits", deprecated: false
  field :synth_supply, 13, type: :string, json_name: "synthSupply", deprecated: false
  field :savers_depth, 14, type: :string, json_name: "saversDepth", deprecated: false
  field :savers_units, 15, type: :string, json_name: "saversUnits", deprecated: false
  field :savers_fill_bps, 16, type: :string, json_name: "saversFillBps", deprecated: false

  field :savers_capacity_remaining, 17,
    type: :string,
    json_name: "saversCapacityRemaining",
    deprecated: false

  field :synth_mint_paused, 18, type: :bool, json_name: "synthMintPaused", deprecated: false

  field :synth_supply_remaining, 19,
    type: :string,
    json_name: "synthSupplyRemaining",
    deprecated: false

  field :loan_collateral, 20, type: :string, json_name: "loanCollateral", deprecated: false

  field :loan_collateral_remaining, 21,
    type: :string,
    json_name: "loanCollateralRemaining",
    deprecated: false

  field :loan_cr, 22, type: :string, json_name: "loanCr", deprecated: false
  field :derived_depth_bps, 23, type: :string, json_name: "derivedDepthBps", deprecated: false
end

defmodule Thorchain.Types.QueryPoolsRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :height, 1, type: :string
end

defmodule Thorchain.Types.QueryPoolsResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :pools, 1, repeated: true, type: Thorchain.Types.QueryPoolResponse
end
