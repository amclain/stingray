defmodule Stingray.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Stingray.Target

  @data_directory Application.compile_env(:stingray, :data_directory)

  @impl Application
  def start(_type, _args) do
    if target() != :host do
      disable_bbb_heartbeat_led()
    end

    if Application.get_env(:stingray, :enable_nfs, false),
      do: Stingray.NFS.start

    File.mkdir_p(@data_directory)

    database_directory = Path.join(@data_directory, "settings")

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
        {Stingray.UploadManager, nil},
      ] ++ children(target())

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        after_start()
        {:ok, pid}

      error ->
        error
    end
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

  @impl Application
  def stop(_state) do
    if Application.get_env(:stingray, :enable_nfs, false),
      do: Stingray.NFS.stop
  end

  def target() do
    Application.get_env(:stingray, :target)
  end

  defp after_start do
    if target() != :host do
      export_target_file_shares()
    end

    ensure_target_upload_directories_exist()
  end

  defp disable_bbb_heartbeat_led do
    File.write("/sys/class/leds/beaglebone:green:usr0/trigger", "none")
  end

  defp export_target_file_shares do
    Enum.each(Target.list, &Target.export_file_share/1)
  end

  defp ensure_target_upload_directories_exist do
    Enum.each(Target.list, &Target.ensure_upload_directory_exists/1)
  end
end
