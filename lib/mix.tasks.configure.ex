defmodule Mix.Tasks.Farmbot.Configure do
  use Mix.Task
  @shortdoc "Configure you're farmbot account."

  def run([email, password, server]) do
    Application.ensure_all_started(:httpoison)

    case HostFarmwareTools.fetch_token(email, password, server) do
      {:ok, _tkn} ->
        secret =
          %{email: email, password: password, server: server}
          |> :erlang.term_to_binary()
          |> Base.encode64()

        File.write!("secret", secret)

      {:error, reason} ->
        Mix.raise(reason)
    end
  end

  def run(_) do
    Mix.raise("mix farmbot.configure email password server")
  end
end
