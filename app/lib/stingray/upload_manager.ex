defmodule Stingray.UploadManager do
  @moduledoc """
  Manages firmware uploads received from a host and shares them on the network.
  """

  use GenServer

  require Logger

  defmodule State do
    @moduledoc false
    defstruct [:file_system_pid]
  end

  @uploads_directory \
    Application.compile_env(:stingray, :data_directory)
    |> Path.join("uploads")

  def start_link(_args) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    File.mkdir_p(@uploads_directory)

    {:ok, %State{}, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, state) do
    {:ok, pid} = FileSystem.start_link(dirs: [@uploads_directory])
    FileSystem.subscribe(pid)

    state = %State{state | file_system_pid: pid}

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:file_event, _worker_pid, {file_path, [:modified, :closed]}}, state) do
    cond do
      String.ends_with?(file_path, ".fw") ->
        unpack_nerves_firmware(file_path)

      true ->
        :noop
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _worker_pid, {_file_path, _events}}, state) do
    {:noreply, state}
  end

  @doc false
  def unpack_nerves_firmware(file_path) do
    file_dir = file_path |> Path.dirname

    Logger.debug "Received firmware #{file_path}"

    {:ok, _} = :zip.unzip(
      to_charlist(file_path),
      cwd: to_charlist(file_dir),
      file_list: ['data/rootfs.img']
    )

    mount_path = Path.join(file_dir, "rootfs")
    image_path = Path.join([file_dir, "data", "rootfs.img"])
    share_path = String.replace(file_dir, ~r|^/data/uploads/(\w+).*|, "/data/share/\\1/rootfs")

    File.mkdir_p(mount_path)

    case MuonTrap.cmd("mount", ["-o", "loop", image_path, mount_path]) do
      {_, 0} ->
        File.rm_rf(share_path)
        File.mkdir_p(share_path)

        File.cp_r(mount_path, share_path)

        Logger.info "Sharing firmware #{file_path}\n  at #{share_path}"

        MuonTrap.cmd("umount", [mount_path])

        File.rm_rf(mount_path)
        File.rm_rf(file_path)
        File.rm_rf(Path.join(file_dir, "data"))

      _error ->
        raise "Failed to mount #{image_path}"
    end
  end
end
