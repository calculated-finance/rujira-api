defmodule RujiraWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use RujiraWeb, :controller
      use RujiraWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: RujiraWeb.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: RujiraWeb.Endpoint,
        router: RujiraWeb.Router,
        statics: RujiraWeb.static_paths()
    end
  end

  def check_origin(%{scheme: "exp"}), do: true
  def check_origin(%{scheme: "http", host: "localhost"}), do: true
  def check_origin(%{scheme: "https", host: "rujira.network"}), do: true
  def check_origin(%{scheme: "https", host: "preview.rujira.network"}), do: true
  def check_origin(%{scheme: "https", host: "rujira-ui-main.vercel.app"}), do: true
  def check_origin(%{scheme: "https", host: "ai.autorujira.app"}), do: true

  def check_origin(%{scheme: "https", host: host} = x) do
    Enum.any?(
      [
        ~r/^.*\.levana\-perps\-webapp\.pages\.dev/,
        ~r/^.*\.rujiperps.com/,
        ~r/^rujira-ui-main-git-[a-z]+-rujira\.vercel\.app/,
        ~r/^preview-api\.rujira\.network/,
        ~r/^api\.rujira\.network/
      ],
      &Regex.match?(&1, host)
    )
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
