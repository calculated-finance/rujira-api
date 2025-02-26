defmodule Thorchain.Types.MsgLoanOpen do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :owner, 1, type: :string, deprecated: false

  field :collateral_asset, 2,
    type: Thorchain.Common.Asset,
    json_name: "collateralAsset",
    deprecated: false

  field :collateral_amount, 3, type: :string, json_name: "collateralAmount", deprecated: false
  field :target_address, 4, type: :string, json_name: "targetAddress", deprecated: false

  field :target_asset, 5,
    type: Thorchain.Common.Asset,
    json_name: "targetAsset",
    deprecated: false

  field :min_out, 6, type: :string, json_name: "minOut", deprecated: false
  field :affiliate_address, 7, type: :string, json_name: "affiliateAddress", deprecated: false

  field :affiliate_basis_points, 8,
    type: :string,
    json_name: "affiliateBasisPoints",
    deprecated: false

  field :aggregator, 9, type: :string
  field :aggregator_target_address, 10, type: :string, json_name: "aggregatorTargetAddress"

  field :aggregator_target_limit, 11,
    type: :string,
    json_name: "aggregatorTargetLimit",
    deprecated: false

  field :signer, 12, type: :bytes, deprecated: false
  field :tx_id, 13, type: :string, json_name: "txId", deprecated: false
end

defmodule Thorchain.Types.MsgLoanRepayment do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :owner, 1, type: :string, deprecated: false

  field :collateral_asset, 2,
    type: Thorchain.Common.Asset,
    json_name: "collateralAsset",
    deprecated: false

  field :coin, 3, type: Thorchain.Common.Coin, deprecated: false
  field :min_out, 4, type: :string, json_name: "minOut", deprecated: false
  field :signer, 5, type: :bytes, deprecated: false
  field :from, 6, type: :string, deprecated: false
  field :tx_id, 7, type: :string, json_name: "txId", deprecated: false
end
