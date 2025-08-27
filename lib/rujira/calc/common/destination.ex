defmodule Rujira.Calc.Common.Destination do
  alias Rujira.Calc.Common.Recipient

  defstruct shares: 0,
            recipient: Recipient.default(),
            label: nil

  @type t :: %__MODULE__{
          shares: non_neg_integer(),
          recipient: Recipient.t(),
          label: String.t() | nil
        }

  def from_config(%{"shares" => shares, "recipient" => recipient, "label" => label}) do
    with {:ok, recipient} <- Recipient.from_config(recipient) do
      {:ok,
       %__MODULE__{
         shares: shares,
         recipient: recipient,
         label: label
       }}
    end
  end
end
