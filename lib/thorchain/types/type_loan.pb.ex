defmodule Thorchain.Types.Loan do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :owner, 1, type: :string, deprecated: false
  field :asset, 2, type: Thorchain.Common.Asset, deprecated: false
  field :debt_issued, 3, type: :string, json_name: "debtIssued", deprecated: false
  field :debt_repaid, 4, type: :string, json_name: "debtRepaid", deprecated: false

  field :collateral_deposited, 5,
    type: :string,
    json_name: "collateralDeposited",
    deprecated: false

  field :collateral_withdrawn, 6,
    type: :string,
    json_name: "collateralWithdrawn",
    deprecated: false

  field :last_open_height, 9, type: :int64, json_name: "lastOpenHeight"
  field :last_repay_height, 10, type: :int64, json_name: "lastRepayHeight"
end
