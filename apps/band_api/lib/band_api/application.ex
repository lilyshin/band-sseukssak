defmodule BandApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BandApiWeb.Telemetry,
      # BandApi.Repo,  # 데이터베이스 비활성화
      {DNSCluster, query: Application.get_env(:band_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BandApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: BandApi.Finch},
      # Start a worker by calling: BandApi.Worker.start_link(arg)
      # {BandApi.Worker, arg},
      # Start to serve requests, typically the last entry
      BandApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BandApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BandApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
