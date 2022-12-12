defmodule Stingray.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    disable_bbb_heartbeat_led()

    Stingray.NFS.init
    Stingray.NFS.start

    data_directory =
      Application.fetch_env!(:stingray, :data_directory)
      |> Path.expand

    File.mkdir_p(data_directory)

    database_directory = Path.join(data_directory, "settings")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Stingray.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: Stingray.Worker.start_link(arg)
        # {Stingray.Worker, arg},
        {CubDB, [name: :settings, data_dir: database_directory]},
        {Stingray.PowerManager, nil},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: Stingray.Worker.start_link(arg)
      # {Stingray.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: Stingray.Worker.start_link(arg)
      # {Stingray.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:stingray, :target)
  end

  defp disable_bbb_heartbeat_led do
    File.write("/sys/class/leds/beaglebone:green:usr0/trigger", "none")
  end
end
