defmodule RujiraWeb.Router do
  use RujiraWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    scope "/trade" do
      get "/tickers", RujiraWeb.TradeController, :tickers
      get "/orderbook", RujiraWeb.TradeController, :orderbook
      get "/historical_trades", RujiraWeb.TradeController, :trades
    end

    scope "/ruji" do
      get "/total_supply", RujiraWeb.RujiController, :total_supply
      get "/circulating_supply", RujiraWeb.RujiController, :circulating_supply
    end

    get "/schema/:schema", RujiraWeb.SchemaController, :show

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: RujiraWeb.Schema,
      socket: RujiraWeb.UserSocket

    forward "/", Absinthe.Plug, schema: RujiraWeb.Schema
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:rujira, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: RujiraWeb.Telemetry
    end
  end
end
