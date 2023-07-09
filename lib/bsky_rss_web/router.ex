defmodule BskyRssWeb.Router do
  use BskyRssWeb, :router

  alias BskyRss.Auth
  alias BskyRss.Bsky

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BskyRssWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :bluesky do
    plug LoggerJSON.Plug
    plug :auth
  end

  scope "/", BskyRssWeb do
    pipe_through :bluesky
    get "/", RssController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", BskyRssWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bsky_rss, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BskyRssWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  defp auth(conn, _opts) do
    {user, pass} = Plug.BasicAuth.parse_basic_auth(conn)
    client = Bsky.client()
    session = Auth.session(client, user, pass)
    Logger.metadata(user: user)

    conn
    |> assign(:session, session)
    |> assign(:client, client)
    |> assign(:user, user)
  end
end
