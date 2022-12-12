defmodule Stingray.NFS do
  @moduledoc """
  Network file system

  This module manages:
  - [exportfs](https://linux.die.net/man/8/exportfs)
  - [nfsd](https://linux.die.net/man/8/nfsd)
  - [rpcbind](https://man7.org/linux/man-pages/man8/rpcbind.8.html)
  - [rpc.statd](https://linux.die.net/man/8/rpc.statd)
  - [rpc.mountd](https://linux.die.net/man/8/rpc.mountd)
  """

  require Logger

  @doc """
  Start the NFS services.

  This function is NOT idempotent.
  """
  @spec start() :: :ok
  def start do
    File.mkdir_p("/var/lock/subsys")
    File.mkdir_p("/run/nfs/sm")
    File.mkdir_p("/run/nfs/sm.bak")
    File.touch("/run/nfs/rmtab")

    Logger.info "Starting rpcbind"
    {_, 0} = MuonTrap.cmd("rpcbind", [], stderr_to_stdout: true)

    Logger.info "Starting NFS statd"
    {_, 0} = MuonTrap.cmd("rpc.statd", [], stderr_to_stdout: true)
    File.touch("/var/lock/subsys/nfslock")

    Logger.info "Starting NFS services"
    {_, 0} = MuonTrap.cmd("exportfs", ["-r"], stderr_to_stdout: true)

    Logger.info "Starting NFS daemon"
    {_, 0} = MuonTrap.cmd("rpc.nfsd", [], stderr_to_stdout: true)

    Logger.info "Starting NFS mountd"
    {_, 0} = MuonTrap.cmd("rpc.mountd", [], stderr_to_stdout: true)
    File.touch("/var/lock/subsys/nfs")

    :ok
  end

  @doc """
  Stop the NFS services.

  This function is NOT idempotent.
  """
  @spec stop() :: :ok
  def stop do
    Logger.info "Shutting down NFS mountd"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpc.mountd"], stderr_to_stdout: true)

    Logger.info "Shutting down NFS daemon"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "nfsd"], stderr_to_stdout: true)

    Logger.info "Shutting down NFS services"
    {_, 0} = MuonTrap.cmd("exportfs", ["-au"], stderr_to_stdout: true)

    Logger.info "Shutting down NFS statd"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpc.statd"], stderr_to_stdout: true)

    Logger.info "Shutting down rpcbind"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpcbind"], stderr_to_stdout: true)

    File.rm_rf("/var/lock/subsys/nfs")
    File.rm_rf("/var/run/rpc.statd.pid")
    File.rm_rf("/var/lock/subsys/nfslock")

    :ok
  end

  @doc """
  Reload the exports file.

  This will remove any exports added at runtime.
  """
  @spec reload() :: :ok, {:error, code :: non_neg_integer}
  def reload do
    case MuonTrap.cmd("exportfs", ["-r"]) do
      {_stdout, 0} ->
        File.touch("/var/lock/subsys/nfs")
        :ok

      {_stdout, code} ->
        {:error, code}
    end
  end

  @doc """
  List all of the paths being exported.
  """
  @spec list_exports() :: [path :: String.t] | {:error, code :: non_neg_integer}
  def list_exports do
    case MuonTrap.cmd("exportfs", ["-s"]) do
      {stdout, 0} ->
        stdout
        |> String.replace(~r/^(\S+).*?$/m, "\\1")
        |> String.split

      {_stdout, code} ->
        {:error, code}
    end
  end

  @doc """
  Export a path.
  """
  @spec export(path :: String.t) :: :ok | {:error, code :: non_neg_integer}
  def export(path) do
    File.mkdir_p(path)

    result = MuonTrap.cmd("exportfs", [
      "-o", "ro,sync,no_subtree_check,no_root_squash",
      "*:#{path}"
    ])
    
    case result do
      {_stdout, 0}    -> :ok
      {_stdout, code} -> {:error, code}
    end
  end

  @doc """
  Unexport a path.

  Use `:all` to unexport all paths.
  """
  @spec unexport(path :: String.t | :all) :: :ok | {:error, code :: non_neg_integer}
  def unexport(:all) do
    case MuonTrap.cmd("exportfs", ["-ua"]) do
      {_stdout, 0}    -> :ok
      {_stdout, code} -> {:error, code}
    end
  end

  def unexport(path) do
    case MuonTrap.cmd("exportfs", ["-u", "*:#{path}"]) do
      {_stdout, 0}    -> :ok
      {_stdout, code} -> {:error, code}
    end
  end
end
