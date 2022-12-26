defmodule Stringray.Target.Test do
  use ESpec

  alias Stingray.NFS
  alias Stingray.Target

  let :target_number,           do: 1
  let :target_id,               do: :my_target
  let :target_name,             do: "My Target"
  let :target_serial_port,      do: "ttyUSB0"
  let :target_baud,             do: 115200
  let :target_file_system_name, do: "my-target"

  before_all do
    Application.put_env(:stingray, :enable_nfs, true)
  end

  after_all do
    Application.put_env(:stingray, :enable_nfs, false)
  end

  before do
    allow File |> to(accept :mkdir_p,  fn _path -> :ok end)
    allow NFS  |> to(accept :export,   fn _path -> :ok end)
    allow NFS  |> to(accept :unexport, fn _path -> :ok end)

    {:ok, target} = Target.add(
      target_number(),
      target_id(),
      target_name(),
      target_serial_port(),
      target_baud()
    )

    {:shared, target: target}
  end

  describe "add a target" do
    specify do
      new_target = %Target{
        number:               2,
        id:                   :my_new_target,
        name:                 "My New Target",
        serial_port:          "ttyUSB0",
        baud:                 115200,
        uboot_console_string: nil,
      }

      share_path  = target_share_path(new_target)
      upload_path = target_upload_path(new_target)

      allow File |> to(accept :mkdir_p, fn
        ^share_path     -> :ok
        ^upload_path    -> :ok
        unexpected_path -> raise "Unexpectedly tried to create #{unexpected_path}"
      end)

      expect Target.add(2, :my_new_target, "My New Target", "ttyUSB0", 115200)
      |> to(eq {:ok, new_target})

      # One of these counts is for the default target that's set up before this
      # test runs.
      expect File |> to(accepted :mkdir_p, :any, count: 4)
      expect NFS  |> to(accepted :export,  :any, count: 2)
    end

    specify "with a U-Boot console string" do
      expect Target.add(
        2,
        :my_new_target,
        "My New Target",
        "ttyUSB0",
        115200,
        uboot_console_string: "st1ngr4y"
      )|> to(eq \
        {:ok, %Target{
          number:               2,
          id:                   :my_new_target,
          name:                 "My New Target",
          serial_port:          "ttyUSB0",
          baud:                 115200,
          uboot_console_string: "st1ngr4y",
        }
      })
    end

    it "returns an error if the target exists" do
      expect Target.add(target_number(), :my_new_target, target_name(), target_serial_port(), target_baud())
      |> to(eq {:error, :target_exists})

      expect Target.add(1000, target_id(), target_name(), target_serial_port(), target_baud())
      |> to(eq {:error, :target_exists})
    end

    it "returns an error when adding a target with invalid params" do
      expect Target.add(-1, :my_new_target, "My Target", "ttyUSB0", 115200)
      |> should(eq {:error, :number_not_positive})

      expect Target.add(1000, "invalid id", "My Target", "ttyUSB0", 115200)
      |> should(eq {:error, :id_not_atom})

      expect Target.add(1000, :my_new_target, nil, "ttyUSB0", 115200)
      |> should(eq {:error, :name_not_string})

      expect Target.add(1000, :my_new_target, "My Target", nil, 115200)
      |> should(eq {:error, :serial_port_not_string})

      expect Target.add(1000, :my_new_target, "My Target", "ttyUSB0", nil)
      |> should(eq {:error, :invalid_baud})
    end
  end

  describe "get a target" do
    specify do
      expect Target.get(target_id()) |> should(eq shared.target)
    end

    it "returns nil if the target isn't found" do
      expect Target.get(:invalid_target) |> should(eq nil)
    end
  end

  it "lists targets in numerical order" do
    Target.add(5, :target_5, "Target 5", "ttyUSB5", 9600)
    Target.add(3, :target_3, "Target 3", "ttyUSB3", 115200, uboot_console_string: "st1ngr4y")

    expect Target.list |> to(eq [
      %Target{
        number:               target_number(),
        id:                   target_id(),
        name:                 target_name(),
        serial_port:          target_serial_port(),
        baud:                 target_baud(),
        uboot_console_string: nil,
      },
      %Target{
        number:               3,
        id:                   :target_3,
        name:                 "Target 3",
        serial_port:          "ttyUSB3",
        baud:                 115200,
        uboot_console_string: "st1ngr4y",
      },
      %Target{
        number:               5,
        id:                   :target_5,
        name:                 "Target 5",
        serial_port:          "ttyUSB5",
        baud:                 9600,
        uboot_console_string: nil,
      },
    ])
  end

  describe "remove a target" do
    specify do
      share_path  = target_share_path(shared.target)
      upload_path = target_upload_path(shared.target)

      allow File |> to(accept :rm_rf, fn
        ^share_path     -> :ok
        ^upload_path    -> :ok
        unexpected_path -> raise "Unexpectedly tried to remove #{unexpected_path}"
      end)

      expect Target.remove(target_id()) |> should(eq {:ok, shared.target})
      expect Target.list |> should(eq [])

      expect File |> to(accepted :rm_rf,    :any, count: 2)
      expect NFS  |> to(accepted :unexport, :any, count: 1)
    end

    it "returns an error if the target doesn't exist" do
      expect Target.remove(:invalid_target) |> should(eq {:error, :not_found})
      expect Target.list |> should(eq [shared.target])
    end
  end

  describe "set properties of a target" do
    specify "by target id" do
      changed_target = %Target{
        number:               1,
        id:                   :changed_target,
        name:                 "New name",
        serial_port:          "ttyNew0",
        baud:                 9600,
        uboot_console_string: "st1ngr4y",
      }

      allow NFS |> to(accept :unexport, fn path ->
        expect path |> to(eq target_share_path(shared.target))
        :ok
      end)

      allow NFS |> to(accept :export, fn path ->
        expect path |> to(eq target_share_path(changed_target))
        :ok
      end)

      share_path  = target_share_path(changed_target)
      upload_path = target_upload_path(changed_target)

      allow File |> to(accept :mkdir_p, fn
        ^share_path     -> :ok
        ^upload_path    -> :ok
        unexpected_path -> raise "Unexpectedly tried to create #{unexpected_path}"
      end)

      old_share_path  = target_share_path(shared.target)
      old_upload_path = target_upload_path(shared.target)

      allow File |> to(accept :rename, fn
        ^old_share_path, new_path ->
          expect new_path |> to(eq target_share_path(changed_target))
          :ok

        ^old_upload_path, new_path ->
          expect new_path |> to(eq target_upload_path(changed_target))
          :ok

        unexpected_path, new_path ->
          raise "Unexpectedly tried to rename #{unexpected_path} to #{new_path}"
      end)

      expect Target.set(
        target_id(),
        id:                   :changed_target,
        name:                 "New name",
        serial_port:          "ttyNew0",
        baud:                 9600,
        uboot_console_string: "st1ngr4y"
      )
      |> to(eq {:ok, changed_target})

      expect Target.list() |> to(eq [changed_target])

      expect NFS  |> to(accepted :unexport, :any, count: 1)
      expect NFS  |> to(accepted :export,   :any, count: 2)
      expect File |> to(accepted :mkdir_p,  :any, count: 3)
      expect File |> to(accepted :rename,   :any, count: 2)
    end

    specify "by target handle" do
      changed_target = %Target{
        number:               1,
        id:                   :changed_target,
        name:                 "New name",
        serial_port:          "ttyNew0",
        baud:                 9600,
        uboot_console_string: "st1ngr4y",
      }

      expect Target.set(
        target_id(),
        id:                   :changed_target,
        name:                 "New name",
        serial_port:          "ttyNew0",
        baud:                 9600,
        uboot_console_string: "st1ngr4y"
      )
      |> to(eq {:ok, changed_target})

      expect Target.list() |> to(eq [changed_target])
    end

    it "returns an error if the target ID doesn't exist" do
      expect Target.set(:invalid_target, name: "New name")
      |> to(eq {:error, :target_not_found})
    end

    it "returns an error if the target handle doesn't exist" do
      expect Target.set(%Target{}, name: "New name")
      |> to(eq {:error, :target_not_found})
    end

    it "ignores target properties that don't exist" do
      expect Target.set(shared.target, invalid: "Can't set this")
      |> to(eq {:ok, shared.target})
    end
  end

  describe "file share" do
    it "can be exported for a target" do
      allow File |> to(accept :mkdir_p, fn _ -> :ok end)
      
      allow NFS |> to(accept :export, fn path ->
        expect path |> to(eq target_share_path(shared.target))
        :ok
      end)

      expect Target.export_file_share(shared.target) |> to(eq :ok)

      expect File |> to(accepted :mkdir_p, :any, count: 3)
      expect NFS  |> to(accepted :export,  :any, count: 2)
    end

    it "can be unexported for a target" do
      allow NFS |> to(accept :unexport, fn path ->
        expect path |> to(eq target_share_path(shared.target))
        :ok
      end)

      expect Target.unexport_file_share(shared.target) |> to(eq :ok)

      expect NFS |> to(accepted :unexport, :any, count: 1)
    end
  end

  describe "file system name" do
    specify "of a target" do
      expect Target.file_system_name(shared.target)
      |> to(eq target_file_system_name())
    end

    specify "of a target's ID as an atom" do
      expect Target.file_system_name(target_id())
      |> to(eq target_file_system_name())
    end

    specify "of a target's ID as a string" do
      expect Target.file_system_name(to_string(target_id()))
      |> to(eq target_file_system_name())
    end
  end

  specify "ensure upload directory exists" do
    expected_path = Path.join([
      Application.get_env(:stingray, :data_directory),
      "uploads",
      target_file_system_name(),
    ])

    allow File |> to(accept :mkdir_p, fn path ->
      expect path |> to(eq expected_path)
      :ok
    end)

    expect Target.ensure_upload_directory_exists(shared.target)
    |> to(eq :ok)

    expect File |> to(accepted :mkdir_p, :any, count: 3)
  end

  defp target_share_path(target) do
    Path.join([
      Application.get_env(:stingray, :data_directory),
      "share",
      Target.file_system_name(target),
    ])
  end

  defp target_upload_path(target) do
    Path.join([
      Application.get_env(:stingray, :data_directory),
      "uploads",
      Target.file_system_name(target),
    ])
  end
end
