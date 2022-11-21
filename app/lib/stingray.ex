defmodule Stingray do
  @moduledoc """
  Build farm automation and remote management.
  """

  alias Stingray.Target

  @doc """
  Open a console to a target given its ID.
  """
  @spec console(target_id :: atom) ::
      :done
    | {:error, :target_not_found}
    | {:error, :serial_port_not_found, device_path :: String.t}
    | {:error, :command_failed, exit_code :: non_neg_integer}
  def console(target_id) do
    case Target.get(target_id) do
      nil ->
        {:error, :target_not_found}

      target ->
        device_path = Path.join("/dev", target.serial_port)

        case File.exists?(device_path) do
          false ->
            {:error, :serial_port_not_found, device_path}

          _ ->
            Stingray.Console.open(target.serial_port, 115200)
        end
    end
  end
end
