defmodule HostFarmwareTools do

  def fetch_token(email, password, server) do
    with {:ok, rsa_key} <- request_rsa_key(server),
         {:ok, pl} <- build_payload(email, password, rsa_key) do
      request_token(server, pl)
    end
  end

  def build_payload(email, password, rsa_key) do
    secret =
      %{email: email, password: password, id: UUID.uuid1(), version: 1}
      |> Jason.encode!()
      |> RSA.encrypt({:public, rsa_key})

    %{user: %{credentials: secret |> Base.encode64()}} |> Jason.encode()
  end

  def request_rsa_key(server) do
    url = "#{server}/api/public_key"

    case HTTPoison.get(url, [], [follow_redirect: false]) do
      {:ok, %{status_code: 200, body: body}} ->
        r = body |> to_string() |> RSA.decode_key()
        {:ok, r}

      {:ok, %{status_code: code, body: body}} ->
        msg = """
        Failed to fetch public key.
        status_code: #{code}
        body: #{body}
        """

        {:error, msg}

      {:error, error} ->
        {:error, "http error: #{inspect(error)}"}
    end
  end

  def request_token(server, payload) do
    headers = [
      {"User-Agent", "FarmwareTools/0.0.0"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post("#{server}/api/tokens", payload, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        body |> Jason.decode!() |> Map.fetch("token")

      # if the error is a 4xx code, it was a failed auth.
      {:ok, %{status_code: code, body: body}} when code > 399 and code < 500 ->
        msg = """
        Failed to authorize with the Farmbot web application at: #{server}
        with code: #{code}
        body: #{body}
        """

        {:error, msg}

      # if the error is not 2xx and not 4xx, probably maintance mode.
      {:ok, %{status_code: code}} ->
        {:error, "http error: #{code}"}

      {:error, error} ->
        {:error, "http error: #{inspect(error)}"}
    end
  end

  def fetch_token do
    with {:ok, secret} <- File.read("secret"),
         {:ok, data} <- Base.decode64(secret),
         %{email: email, password: password, server: server} <- :erlang.binary_to_term(data) do
      fetch_token(email, password, server)
    else
      _ -> {:error, "failed to decode secret, delete it and try again"}
    end
  end
end
