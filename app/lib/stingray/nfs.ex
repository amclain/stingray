defmodule Stingray.NFS do
  require Logger

  def export, do: export("/root/nfs/target-01")

  def export(path) do
    File.mkdir_p(path)
    {_, 0} = MuonTrap.cmd("exportfs", ["-o", "ro,sync,no_subtree_check,no_root_squash", "*:#{path}"])
    :ok
  end

  def unexport(:all) do
    {_, 0} = MuonTrap.cmd("exportfs", ["-ua"])
    :ok
  end

  def unexport(path) do
    {_, 0} = MuonTrap.cmd("exportfs", ["-u", "*:#{path}"])
    :ok
  end

  def init do
    File.mkdir_p("/var/lock/subsys")
    File.mkdir_p("/run/nfs/sm")
    File.mkdir_p("/run/nfs/sm.bak")
    File.touch("/run/nfs/rmtab")
  end

  def start do
    Logger.info "Starting rpcbind"
    {_, 0} = MuonTrap.cmd("rpcbind", [])

    Logger.info "Starting NFS statd"
    {_, 0} = MuonTrap.cmd("rpc.statd", [])
    File.touch("/var/lock/subsys/nfslock")

    Logger.info "Starting NFS services"
    {_, 0} = MuonTrap.cmd("exportfs", ["-r"])

    Logger.info "Starting NFS daemon"
    {_, 0} = MuonTrap.cmd("rpc.nfsd", [])

    Logger.info "Starting NFS mountd"
    {_, 0} = MuonTrap.cmd("rpc.mountd", [])
    File.touch("/var/lock/subsys/nfs")

    :ok
  end

  def stop do
    Logger.info "Shutting down NFS mountd"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpc.mountd"])

    Logger.info "Shutting down NFS daemon"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "nfsd"])

    Logger.info "Shutting down NFS services"
    {_, 0} = MuonTrap.cmd("exportfs", ["-au"])

    Logger.info "Shutting down NFS statd"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpc.statd"])

    Logger.info "Shutting down rpcbind"
    {_, 0} = MuonTrap.cmd("killall", ["-q", "rpcbind"])

    File.rm_rf("/var/lock/subsys/nfs")
    File.rm_rf("/var/run/rpc.statd.pid")
    File.rm_rf("/var/lock/subsys/nfslock")

    :ok
  end

  def reload do
    {_, 0} = MuonTrap.cmd("exportfs", ["-r"])
    File.touch("/var/lock/subsys/nfs")

    :ok
  end

  def exports do
    {stdout, 0} = MuonTrap.cmd("exportfs", ["-s"])

    stdout
    |> String.replace(~r/^(\S+).*?$/m, "\\1")
    |> String.split
  end
end
