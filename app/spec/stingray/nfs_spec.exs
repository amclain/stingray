defmodule Stingray.NFS.Test do
  use ESpec

  alias Stingray.NFS

  let :path, do: "/data/nfs/target-01"
  
  it "starts the NFS services" do
    allow File     |> to(accept :mkdir_p, fn _ -> :ok end)
    allow File     |> to(accept :touch,   fn _ -> :ok end)
    allow MuonTrap |> to(accept :cmd,     fn _cmd, _args, _opts -> {"", 0} end)

    capture_log(fn ->
      expect NFS.start |> to(eq :ok)
    end)

    expect File     |> to(accepted :mkdir_p, :any, count: 3)
    expect File     |> to(accepted :touch,   :any, count: 3)
    expect MuonTrap |> to(accepted :cmd,     :any, count: 5)
  end

  it "stops the NFS services" do
    allow File     |> to(accept :rm_rf, fn _ -> :ok end)
    allow MuonTrap |> to(accept :cmd,   fn _cmd, _args, _opts -> {"", 0} end)

    capture_log(fn ->
      expect NFS.stop |> to(eq :ok)
    end)

    expect File     |> to(accepted :rm_rf, :any, count: 3)
    expect MuonTrap |> to(accepted :cmd,   :any, count: 5)
  end

  describe "reload" do
    it "reloads the exports file" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "-r")
        {"", 0}
      end)

      expect NFS.reload |> to(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the command fails" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", _args ->
        {"", 1}
      end)

      expect NFS.reload |> to(eq {:error, 1})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  describe "list exports" do
    it "returns the exports on success" do
      raw_exports = """
      /data/nfs/target-01  *(sync,wdelay,hide,no_subtree_check,sec=sys,ro,secure,no_root_squash,no_all_squash)
      /data/nfs/target-02  *(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
      /data/nfs/target-03  *(async,wdelay,hide,no_subtree_check,sec=sys,ro,secure,no_root_squash,no_all_squash)
      """

      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "-s")
        {raw_exports, 0}
      end)

      expect NFS.list_exports |> to(eq [
        "/data/nfs/target-01",
        "/data/nfs/target-02",
        "/data/nfs/target-03",
      ])

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the command fails" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", _args ->
        {"", 1}
      end)

      expect NFS.list_exports |> to(eq {:error, 1})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  describe "export" do
    it "exposes a path" do
      allow File |> to(accept :mkdir_p, fn mkdir_path ->
        expect mkdir_path |> to(eq path())
        :ok
      end)

      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "*:" <> path())
        {"", 0}
      end)

      expect NFS.export(path()) |> to(eq :ok)

      expect File     |> to(accepted :mkdir_p)
      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the export fails" do
      allow File |> to(accept :mkdir_p, fn mkdir_path ->
        expect mkdir_path |> to(eq path())
        :ok
      end)

      allow MuonTrap |> to(accept :cmd, fn "exportfs", _args ->
        {"", 1}
      end)

      expect NFS.export(path()) |> to(eq {:error, 1})

      expect File     |> to(accepted :mkdir_p)
      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end

  describe "unexport" do
    it "removes a path" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "-u")
        expect args |> to(have "*:" <> path())
        {"", 0}
      end)

      expect NFS.unexport(path()) |> to(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if the unexport fails" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", _args ->
        {"", 1}
      end)

      expect NFS.unexport(path()) |> to(eq {:error, 1})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "removes all paths" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "-ua")
        {"", 0}
      end)

      expect NFS.unexport(:all) |> to(eq :ok)

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end

    it "returns an error if removing all paths fails" do
      allow MuonTrap |> to(accept :cmd, fn "exportfs", args ->
        expect args |> to(have "-ua")
        {"", 1}
      end)

      expect NFS.unexport(:all) |> to(eq {:error, 1})

      expect MuonTrap |> to(accepted :cmd, :any, count: 1)
    end
  end
end
