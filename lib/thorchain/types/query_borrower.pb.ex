defmodule Thorchain.Types.QueryBorrowerRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string
  field :address, 2, type: :string
  field :height, 3, type: :string
end

defmodule Thorchain.Types.QueryBorrowerResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :owner, 1, type: :string, deprecated: false
  field :asset, 2, type: :string, deprecated: false
  field :debt_issued, 3, type: :string, json_name: "debtIssued", deprecated: false
  field :debt_repaid, 4, type: :string, json_name: "debtRepaid", deprecated: false
  field :debt_current, 5, type: :string, json_name: "debtCurrent", deprecated: false

  field :collateral_deposited, 6,
    type: :string,
    json_name: "collateralDeposited",
    deprecated: false

  field :collateral_withdrawn, 7,
    type: :string,
    json_name: "collateralWithdrawn",
    deprecated: false

  field :collateral_current, 8, type: :string, json_name: "collateralCurrent", deprecated: false
  field :last_open_height, 9, type: :int64, json_name: "lastOpenHeight", deprecated: false
  field :last_replay_height, 10, type: :int64, json_name: "lastReplayHeight", deprecated: false
end

defmodule Thorchain.Types.QueryBorrowersRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string
  field :height, 2, type: :string
end

defmodule Thorchain.Types.QueryBorrowersResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :borrowers, 1, repeated: true, type: Thorchain.Types.QueryBorrowerResponse
end
