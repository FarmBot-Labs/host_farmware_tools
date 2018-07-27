defmodule HostFarmwareTools.Cli do
  def main([email, password, server, directory]) do
    with {:ok, token} <- HostFarmwareTools.fetch_token(email, password, server),
    {:ok, pid} <- HostFarmwareTools.Application.start(:normal, [token, directory]),
    _ <- Process.link(pid)
    do
      cli()
    else
      error -> System.halt("error getting auth token: #{inspect error}")
    end
  end

  def cli do
    IO.gets(">> ")
    |> String.trim()
    |> handle_cli()
    cli()
  end

  def handle_cli(cmd) do
    IO.puts "unable to handle: #{cmd}"
  end
end
