defmodule RujiraWeb.Fragments.DeveloperFragments do
  @state_entry_fragment """
  fragment StateEntryFragment on StateEntry {
    key
    keyAscii
    value
  }
  """

  @tx_position_fragment """
  fragment TxPositionFragment on TxPosition {
    blockHeight
    txIndex
  }
  """

  @contract_info_fragment """
  fragment ContractInfoFragment on ContractInfo {
    codeId
    creator
    admin
    label
    created {
      ...TxPositionFragment
    }
    ibcPortId
    extension
  }
  #{@tx_position_fragment}
  """

  @contract_fragment """
  fragment ContractFragment on Contract {
    id
    address
    info {
      ...ContractInfoFragment
    }
    config
    querySmart(query: "")
    state {
      ...StateEntryFragment
    }
  }
  #{@contract_info_fragment}
  #{@state_entry_fragment}
  """

  @code_fragment """
  fragment CodeFragment on Code {
    id
    checksum
    creator
    contracts {
      ...ContractFragment
    }
  }
  #{@contract_fragment}
  """

  @developer_fragment """
  fragment DeveloperFragment on Developer {
    codes {
      ...CodeFragment
    }
  }
  #{@code_fragment}
  """

  def get_developer_fragment(), do: @developer_fragment
  def get_code_fragment(), do: @code_fragment
  def get_contract_fragment(), do: @contract_fragment
  def get_contract_info_fragment(), do: @contract_info_fragment
  def get_state_entry_fragment(), do: @state_entry_fragment
  def get_tx_position_fragment(), do: @tx_position_fragment
end
