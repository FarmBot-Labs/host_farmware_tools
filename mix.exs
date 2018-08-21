defmodule HostFarmwareTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :host_farmware_tools,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: HostFarmwareTools.Cli],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {HostFarmwareTools.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.0"},
      {:ranch_proxy_protocol, "~> 2.0", override: true},
      {:plug, "~> 1.0"},
      {:amqp, "~> 1.0"},
      {:httpoison, "~> 1.2"},
      {:uuid, "~> 1.1"},
      {:jason, "~> 1.1"},
      {:rsa, "~> 0.0.1"},
      {:fs, "~> 3.4"}
    ]
  end
end
