defmodule HostFarmwareTools.BotConnection do
  use GenServer
  use AMQP
  require Logger
  alias __MODULE__, as: State

  @exchange "amq.topic"

  def uuid(client) do
    client <> "-" <> UUID.uuid1()
  end

  def to_client(uuid, seperator), do: Enum.join(to_client(uuid), seperator)
  def to_client(uuid), do: ["bot", uuid, "from_device"]

  def from_clients(uuid, seperator), do: ["bot", uuid, "from_clients"] |> Enum.join(seperator)
  def status(uuid, seperator), do: ["bot", uuid, "status"] |> Enum.join(seperator)
  def sync(uuid, seperator), do: ["bot", uuid, "sync", "#"] |> Enum.join(seperator)
  def logs(uuid, seperator), do: ["bot", uuid, "logs"] |> Enum.join(seperator)

  def start_link([%{} = token, directory]) do
    GenServer.start_link(__MODULE__, [token, directory])
  end

  def start([%{} = token, directory]) do
    GenServer.start(__MODULE__, [token, directory])
  end

  defstruct [:conn, :chan, :bot, :ping_timeout, :fs_pid]

  def init([token, dir]) do
    with {:ok, conn} <- open_connection(token["encoded"], token["unencoded"]["bot"], token["unencoded"]["mqtt"], token["unencoded"]["vhost"]),
         {:ok, chan} <- AMQP.Channel.open(conn),
         q_name <- uuid("host_farmware_tools"),
         :ok <- Basic.qos(chan, global: true),
         {:ok, _} <- AMQP.Queue.declare(chan, q_name, auto_delete: true),
         :ok <- AMQP.Queue.bind(chan, q_name, @exchange, routing_key: to_client(token["unencoded"]["bot"], ".")),
         :ok <- AMQP.Queue.bind(chan, q_name, @exchange, routing_key: status(token["unencoded"]["bot"], ".")),
         :ok <- AMQP.Queue.bind(chan, q_name, @exchange, routing_key: sync(token["unencoded"]["bot"], ".")),
         :ok <- AMQP.Queue.bind(chan, q_name, @exchange, routing_key: logs(token["unencoded"]["bot"], ".")),
         {:ok, _tag} <- Basic.consume(chan, q_name, self(), no_ack: true),
         :ok <- File.mkdir_p(dir),
         {:ok, fs_pid} <- :fs.start_link(:fs_watcher, to_charlist(dir)),
         :ok <- :fs.subscribe(:fs_watcher),
         state <- %State{conn: conn, chan: chan, bot: token["unencoded"]["bot"], fs_pid: fs_pid} do
      {:ok, state}
    end
  end

  defp open_connection(unencoded, bot, mqtt, vhost) do
    opts = [host: mqtt, username: bot, password: unencoded, virtual_host: vhost]
    AMQP.Connection.open(opts)
  end

  def handle_info({:basic_consume_ok, _}, state) do
    Logger.info("AMQP connected.")
    {:noreply, state}
  end

  def handle_info({_pid, {:fs, :file_event}, {path, actions}}, state) do
    Logger.info("File event: #{inspect actions}: #{to_string(path)}")
    {:noreply, state}
  end
end
