defmodule Amino.PbExtension do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.13.0"

  extend(Google.Protobuf.MessageOptions, :name, 11_110_001, optional: true, type: :string)

  extend(Google.Protobuf.MessageOptions, :message_encoding, 11_110_002,
    optional: true,
    type: :string,
    json_name: "messageEncoding"
  )

  extend(Google.Protobuf.FieldOptions, :encoding, 11_110_003, optional: true, type: :string)

  extend(Google.Protobuf.FieldOptions, :field_name, 11_110_004,
    optional: true,
    type: :string,
    json_name: "fieldName"
  )

  extend(Google.Protobuf.FieldOptions, :dont_omitempty, 11_110_005,
    optional: true,
    type: :bool,
    json_name: "dontOmitempty"
  )

  extend(Google.Protobuf.FieldOptions, :oneof_name, 11_110_006,
    optional: true,
    type: :string,
    json_name: "oneofName"
  )
end
