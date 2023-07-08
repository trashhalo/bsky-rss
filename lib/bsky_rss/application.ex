defmodule BskyRss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BskyRssWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: BskyRss.PubSub},
      # Start Finch
      {Finch, name: BskyRss.Finch},
      # Start the Endpoint (http/https)
      BskyRssWeb.Endpoint
      # Start a worker by calling: BskyRss.Worker.start_link(arg)
      # {BskyRss.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BskyRss.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BskyRssWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
