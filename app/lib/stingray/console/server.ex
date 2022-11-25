defmodule Stingray.Console.Server do
  @moduledoc """
  Manages a console connection to a hardware target.
  """

  use GenServer
  use DI

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

  @doc """
  Open a console to a target.

  This function captures `stdin` for the duration of the console connection.

  ## Args
  - `serial_port` - Absolute file path of the serial port the target is \
                    connected to (`/dev/ttyUSB0`).
  - `baud`        - Baud rate of the serial connection to the target (`115200`).
  """
  @spec open(serial_port :: String.t, baud :: non_neg_integer) ::
    :"do not show this result in output"
  def open(serial_port, baud) do
    {:ok, pid} = start_link(serial_port, baud)

    attach(pid)

    GenServer.stop(pid)

    IEx.dont_display_result
  end

  @impl GenServer
  def init({serial_port, baud}) do
    case File.exists?(serial_port) do
      false ->
        {:stop, "Serial port not found: `#{serial_port}`"}

      _ ->
        state = %State{
          baud: baud,
          serial_device_path: serial_port,
        }

        {:ok, state, {:continue, :init}}
    end
  end

  @impl GenServer
  def handle_continue(:init, state) do
    port = di(Port).open(
      {:spawn, "picocom -b #{state.baud} #{state.serial_device_path}"},
      [:use_stdio, :stderr_to_stdout]
    )

    {:noreply, %State{state | port: port}}
  end

  @impl GenServer
  def terminate(_reason, state) do
    di(Port).close(state.port)
  end

  @impl GenServer
  def handle_call({:command, data}, _from, state) do
    response = di(Port).command(state.port, data)
    {:reply, response, state}
  end

  @impl GenServer
  def handle_call(:get_port, _from, state) do
    {:reply, state.port, state}
  end

  @impl GenServer
  def handle_info({_port, {:data, console_data}}, state) do
    IO.write console_data
    {:noreply, state}
  end

  defp start_link(serial_port, baud) do
    GenServer.start_link(__MODULE__, {serial_port, baud})
  end

  defp attach(pid) do
    port = GenServer.call(pid, :get_port)

    wait_for_input_and_send(port, pid)

    IEx.dont_display_result
  end

  defp wait_for_input_and_send(port, pid) do
    data = di(IO).gets("")

    result =
      case Stingray.Console.CommandParser.parse(data) do
        :passthrough ->
          GenServer.call(pid, {:command, data})

        :exit ->
          stingray_puts "Console closed"
          :break
      end

    unless result == :break, do: wait_for_input_and_send(port, pid)
  end

  defp stingray_puts(line) do
    IO.puts "\e[0;33m<== #{line} ==>\e[0m"
  end
end
