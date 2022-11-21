defmodule Stingray.Console do
  @moduledoc """
  Manages a console connection to a target.
  """

  use GenServer

  defmodule State do
    @moduledoc false

    defstruct [
      # Baud rate of the serial port. Default 115200.
      :baud,
      # Handle to the Elixir Port.
      :port,
      # Absolute path of the serial port device file (`/dev/ttyUSB0`).
      :serial_device_path,
    ]
  end

  def start_link(serial_port, baud) do
    GenServer.start_link(__MODULE__, {serial_port, baud})
  end

  def open(serial_port, baud) do
    {:ok, pid} = start_link(serial_port, baud)

    attach(pid)

    GenServer.stop(pid)

    IEx.dont_display_result
  end

  def attach(pid) do
    port = GenServer.call(pid, :get_port)

    wait_for_input_and_send(port)

    IEx.dont_display_result
  end

  defp wait_for_input_and_send(port) do
    data = IO.gets("")

    if String.trim_trailing(data) == "#exit" do
      IO.puts "\e[0;33m<== Console closed ==>\e[0m"
    else
      Port.command(port, data)

      wait_for_input_and_send(port)
    end
  end

  @impl GenServer
  def init({serial_port, baud}) do
    serial_device_path = Path.join("/dev", serial_port)

    case File.exists?(serial_device_path) do
      false ->
        {:error, :serial_port_not_found, serial_device_path}

      _ ->
        state = %State{
          baud: baud,
          serial_device_path: serial_device_path,
        }

        {:ok, state, {:continue, :init}}
    end
  end

  @impl GenServer
  def handle_continue(:init, state) do
    port = Port.open(
      {:spawn, "picocom -b #{state.baud} #{state.serial_device_path}"},
      [:use_stdio, :stderr_to_stdout]
    )

    {:noreply, %State{state | port: port}}
  end

  @impl GenServer
  def terminate(reason, state) do
    Port.close(state.port)

    :stop
  end

  @impl GenServer
  def handle_call(:get_port, _from, state) do
    {:reply, state.port, state}
  end

  @impl GenServer
  def handle_info({_port, {:data, msg}}, state) do
    IO.write msg
    {:noreply, state}
  end
end
