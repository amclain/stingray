defmodule Mix.Tasks.Stingray.Upload do
  @shortdoc "Upload a firmware bundle for a target"

  @moduledoc """
  **Upload a firmware bundle for a target**

  `mix stingray.upload <stingray_ip> <target_id> <firmware_path>`

  - `stingray_ip` - IP address, hostname, or domain name of the Stingray device.
  - `target_id` - ID of the Stingray target to upload firmware for. This can \
  be in the form of a string (`my_target`) or atom (`:my_target`).
  - `firmware_path` - Local path to the firmware file for the target.

  The uploader currently only supports Nerves firmware.
  """

  use Mix.Task

  @doc false
  @impl Mix.Task
  def run(args) do
    if Enum.count(args) != 3 do 
      Mix.Task.run("help", ["stingray.upload"])
      IO.puts ""
      Mix.raise "Must provide 3 args"
    end

    [stingray_ip, target_id, firmware_path] = args

    unless File.exists?(firmware_path),
      do: Mix.raise "Firmware file does not exist"

    if File.dir?(firmware_path),
      do: Mix.raise "Firmware is not a file"

    unless System.find_executable("sftp"),
      do: Mix.raise "sftp not found"

    target_name =
      target_id
      |> String.replace(~r/^:?(.*)/, "\\1")
      |> Stingray.Target.file_system_name

    target_path = Path.join("/data/uploads", target_name)

    IO.puts "Uploading #{Path.basename(firmware_path)} to #{stingray_ip} ..."

    case Mix.Shell.Quiet.cmd(
      "echo 'put #{firmware_path}' | sftp #{stingray_ip}:#{target_path}",
      stderr_to_stdout: true
    ) do
      0 ->
        temp_dir       = Path.join(System.tmp_dir!, "stingray/tasks")
        done_file_name = Path.basename(firmware_path) <> ".done"
        done_path      = Path.join(temp_dir, done_file_name)

        File.mkdir_p(temp_dir)
        File.write(done_path, "")

        case Mix.Shell.Quiet.cmd(
          "echo 'put #{done_path}' | sftp #{stingray_ip}:#{target_path}",
          stderr_to_stdout: true
        ) do
          0 -> IO.puts "Done"
          _ -> Mix.raise "File transfer failed"
        end

        File.rm(done_path)

        if File.ls!(temp_dir) == [],
          do: File.rm_rf(temp_dir)

      _ ->
        Mix.raise "File transfer failed"
    end

  end
end
