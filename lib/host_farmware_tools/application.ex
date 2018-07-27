defmodule HostFarmwareTools.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, [token, dir]) do
    children = [
      {HostFarmwareTools.BotConnection, [token, dir]},
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: HostFarmwareTools.Router, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HostFarmwareTools.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start(_type, []) do
    children = [
      Plug.Adapters.Cowboy2.child_spec(scheme: :http, plug: HostFarmwareTools.Router, options: [port: 4001])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HostFarmwareTools.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
