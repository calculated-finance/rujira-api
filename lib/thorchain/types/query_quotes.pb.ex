defmodule Thorchain.Types.QueryQuoteSwapRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :from_asset, 1, type: :string, json_name: "fromAsset"
  field :to_asset, 2, type: :string, json_name: "toAsset"
  field :amount, 3, type: :string
  field :streaming_interval, 4, type: :string, json_name: "streamingInterval"
  field :streaming_quantity, 5, type: :string, json_name: "streamingQuantity"
  field :destination, 6, type: :string
  field :tolerance_bps, 7, type: :string, json_name: "toleranceBps"
  field :refund_address, 8, type: :string, json_name: "refundAddress"
  field :affiliate, 9, repeated: true, type: :string
  field :affiliate_bps, 10, repeated: true, type: :string, json_name: "affiliateBps"
  field :height, 11, type: :string
  field :liquidity_tolerance_bps, 12, type: :string, json_name: "liquidityToleranceBps"
end

defmodule Thorchain.Types.QueryQuoteSwapResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :inbound_address, 1, type: :string, json_name: "inboundAddress"
  field :inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks"
  field :inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds"

  field :outbound_delay_blocks, 4,
    type: :int64,
    json_name: "outboundDelayBlocks",
    deprecated: false

  field :outbound_delay_seconds, 5,
    type: :int64,
    json_name: "outboundDelaySeconds",
    deprecated: false

  field :fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false
  field :router, 7, type: :string
  field :expiry, 8, type: :int64, deprecated: false
  field :warning, 9, type: :string, deprecated: false
  field :notes, 10, type: :string, deprecated: false
  field :dust_threshold, 11, type: :string, json_name: "dustThreshold"
  field :recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn"
  field :recommended_gas_rate, 13, type: :string, json_name: "recommendedGasRate"
  field :gas_rate_units, 14, type: :string, json_name: "gasRateUnits"
  field :memo, 15, type: :string
  field :expected_amount_out, 16, type: :string, json_name: "expectedAmountOut", deprecated: false

  field :max_streaming_quantity, 17,
    type: :int64,
    json_name: "maxStreamingQuantity",
    deprecated: false

  field :streaming_swap_blocks, 18,
    type: :int64,
    json_name: "streamingSwapBlocks",
    deprecated: false

  field :streaming_swap_seconds, 19, type: :int64, json_name: "streamingSwapSeconds"
  field :total_swap_seconds, 20, type: :int64, json_name: "totalSwapSeconds"
end

defmodule Thorchain.Types.QueryQuoteSaverDepositRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string
  field :amount, 2, type: :string
  field :affiliate, 3, repeated: true, type: :string
  field :affiliate_bps, 4, repeated: true, type: :string, json_name: "affiliateBps"
  field :height, 5, type: :string
end

defmodule Thorchain.Types.QueryQuoteSaverDepositResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :inbound_address, 1, type: :string, json_name: "inboundAddress", deprecated: false
  field :inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks"
  field :inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds"
  field :outbound_delay_blocks, 4, type: :int64, json_name: "outboundDelayBlocks"
  field :outbound_delay_seconds, 5, type: :int64, json_name: "outboundDelaySeconds"
  field :fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false
  field :router, 7, type: :string
  field :expiry, 8, type: :int64, deprecated: false
  field :warning, 9, type: :string, deprecated: false
  field :notes, 10, type: :string, deprecated: false
  field :dust_threshold, 11, type: :string, json_name: "dustThreshold"
  field :recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn"

  field :recommended_gas_rate, 13,
    type: :string,
    json_name: "recommendedGasRate",
    deprecated: false

  field :gas_rate_units, 14, type: :string, json_name: "gasRateUnits", deprecated: false
  field :memo, 15, type: :string, deprecated: false
  field :expected_amount_out, 16, type: :string, json_name: "expectedAmountOut"

  field :expected_amount_deposit, 17,
    type: :string,
    json_name: "expectedAmountDeposit",
    deprecated: false
end

defmodule Thorchain.Types.QueryQuoteSaverWithdrawRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string
  field :address, 2, type: :string
  field :withdraw_bps, 3, type: :string, json_name: "withdrawBps"
  field :height, 4, type: :string
end

defmodule Thorchain.Types.QueryQuoteSaverWithdrawResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :inbound_address, 1, type: :string, json_name: "inboundAddress", deprecated: false
  field :inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks"
  field :inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds"

  field :outbound_delay_blocks, 4,
    type: :int64,
    json_name: "outboundDelayBlocks",
    deprecated: false

  field :outbound_delay_seconds, 5,
    type: :int64,
    json_name: "outboundDelaySeconds",
    deprecated: false

  field :fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false
  field :router, 7, type: :string
  field :expiry, 8, type: :int64, deprecated: false
  field :warning, 9, type: :string, deprecated: false
  field :notes, 10, type: :string, deprecated: false
  field :dust_threshold, 11, type: :string, json_name: "dustThreshold"
  field :recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn"

  field :recommended_gas_rate, 13,
    type: :string,
    json_name: "recommendedGasRate",
    deprecated: false

  field :gas_rate_units, 14, type: :string, json_name: "gasRateUnits", deprecated: false
  field :memo, 15, type: :string, deprecated: false
  field :dust_amount, 16, type: :string, json_name: "dustAmount", deprecated: false
  field :expected_amount_out, 17, type: :string, json_name: "expectedAmountOut", deprecated: false
end

defmodule Thorchain.Types.QueryQuoteLoanOpenRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :from_asset, 1, type: :string, json_name: "fromAsset"
  field :to_asset, 2, type: :string, json_name: "toAsset"
  field :amount, 3, type: :string
  field :min_out, 4, type: :string, json_name: "minOut"
  field :destination, 5, type: :string
  field :affiliate, 6, repeated: true, type: :string
  field :affiliate_bps, 7, repeated: true, type: :string, json_name: "affiliateBps"
  field :height, 8, type: :string
end

defmodule Thorchain.Types.QueryQuoteLoanOpenResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :inbound_address, 1, type: :string, json_name: "inboundAddress"
  field :inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks"
  field :inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds"

  field :outbound_delay_blocks, 4,
    type: :int64,
    json_name: "outboundDelayBlocks",
    deprecated: false

  field :outbound_delay_seconds, 5,
    type: :int64,
    json_name: "outboundDelaySeconds",
    deprecated: false

  field :fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false
  field :router, 7, type: :string
  field :expiry, 8, type: :int64, deprecated: false
  field :warning, 9, type: :string, deprecated: false
  field :notes, 10, type: :string, deprecated: false
  field :dust_threshold, 11, type: :string, json_name: "dustThreshold"
  field :recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn"

  field :recommended_gas_rate, 13,
    type: :string,
    json_name: "recommendedGasRate",
    deprecated: false

  field :gas_rate_units, 14, type: :string, json_name: "gasRateUnits", deprecated: false
  field :memo, 15, type: :string
  field :expected_amount_out, 16, type: :string, json_name: "expectedAmountOut", deprecated: false

  field :expected_collateralization_ratio, 17,
    type: :string,
    json_name: "expectedCollateralizationRatio",
    deprecated: false

  field :expected_collateral_deposited, 18,
    type: :string,
    json_name: "expectedCollateralDeposited",
    deprecated: false

  field :expected_debt_issued, 19,
    type: :string,
    json_name: "expectedDebtIssued",
    deprecated: false

  field :streaming_swap_blocks, 20,
    type: :int64,
    json_name: "streamingSwapBlocks",
    deprecated: false

  field :streaming_swap_seconds, 21,
    type: :int64,
    json_name: "streamingSwapSeconds",
    deprecated: false

  field :total_open_loan_seconds, 22,
    type: :int64,
    json_name: "totalOpenLoanSeconds",
    deprecated: false
end

defmodule Thorchain.Types.QueryQuoteLoanCloseRequest do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :from_asset, 1, type: :string, json_name: "fromAsset"
  field :to_asset, 2, type: :string, json_name: "toAsset"
  field :min_out, 3, type: :string, json_name: "minOut"
  field :repay_bps, 4, type: :string, json_name: "repayBps"
  field :loan_owner, 5, type: :string, json_name: "loanOwner"
  field :height, 6, type: :string
end

defmodule Thorchain.Types.QueryQuoteLoanCloseResponse do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :inbound_address, 1, type: :string, json_name: "inboundAddress"
  field :inbound_confirmation_blocks, 2, type: :int64, json_name: "inboundConfirmationBlocks"
  field :inbound_confirmation_seconds, 3, type: :int64, json_name: "inboundConfirmationSeconds"

  field :outbound_delay_blocks, 4,
    type: :int64,
    json_name: "outboundDelayBlocks",
    deprecated: false

  field :outbound_delay_seconds, 5,
    type: :int64,
    json_name: "outboundDelaySeconds",
    deprecated: false

  field :fees, 6, type: Thorchain.Types.QuoteFees, deprecated: false
  field :router, 7, type: :string
  field :expiry, 8, type: :int64, deprecated: false
  field :warning, 9, type: :string, deprecated: false
  field :notes, 10, type: :string, deprecated: false
  field :dust_threshold, 11, type: :string, json_name: "dustThreshold"
  field :recommended_min_amount_in, 12, type: :string, json_name: "recommendedMinAmountIn"
  field :recommended_gas_rate, 13, type: :string, json_name: "recommendedGasRate"
  field :gas_rate_units, 14, type: :string, json_name: "gasRateUnits"
  field :memo, 15, type: :string, deprecated: false
  field :expected_amount_out, 16, type: :string, json_name: "expectedAmountOut", deprecated: false
  field :expected_amount_in, 17, type: :string, json_name: "expectedAmountIn", deprecated: false

  field :expected_collateral_withdrawn, 18,
    type: :string,
    json_name: "expectedCollateralWithdrawn",
    deprecated: false

  field :expected_debt_repaid, 19,
    type: :string,
    json_name: "expectedDebtRepaid",
    deprecated: false

  field :streaming_swap_blocks, 20,
    type: :int64,
    json_name: "streamingSwapBlocks",
    deprecated: false

  field :streaming_swap_seconds, 21,
    type: :int64,
    json_name: "streamingSwapSeconds",
    deprecated: false

  field :total_repay_seconds, 22, type: :int64, json_name: "totalRepaySeconds", deprecated: false
end

defmodule Thorchain.Types.QuoteFees do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.13.0"

  field :asset, 1, type: :string, deprecated: false
  field :affiliate, 2, type: :string
  field :outbound, 3, type: :string
  field :liquidity, 4, type: :string, deprecated: false
  field :total, 5, type: :string, deprecated: false
  field :slippage_bps, 6, type: :int64, json_name: "slippageBps", deprecated: false
  field :total_bps, 7, type: :int64, json_name: "totalBps", deprecated: false
end
