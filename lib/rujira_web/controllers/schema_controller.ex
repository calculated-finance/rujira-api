defmodule RujiraWeb.SchemaController do
  use RujiraWeb, :controller

  def show(conn, %{"schema" => schema}) do
    schema = Module.safe_concat([schema])

    pipeline =
      schema
      |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__())
      |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
      |> Absinthe.Schema.apply_modifiers(schema)

    with {:ok, blueprint, _phases} <-
           Absinthe.Pipeline.run(
             schema.__absinthe_blueprint__(),
             pipeline
           ) do
      send_download(conn, {:binary, inspect(blueprint, pretty: true)}, filename: "schema.graphql")
    end
  end
end
