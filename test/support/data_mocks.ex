defmodule Rujira.DataMocks do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      def get_response(request) do
        case request(request) do
          {:ok, match} -> response(match)
          :error -> {:error, "Unknown request"}
        end
      end
    end
  end
end
