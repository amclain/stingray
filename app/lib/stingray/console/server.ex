defmodule Stingray.Console.Server do
  @moduledoc """
  Manages a console connection to a hardware target.
  """

  use GenServer
  use DI

  defmodule State do
    @moduledoc false

    defstruct [
      # Target.t the console is connected to.
      :target,
      # Handle to the Elixir Port that manages the target's console.
      :port,
      # Absolute path of the serial port device file (`/dev/ttyUSB0`).
      :serial_device_path,
      # State machine for rebooting and entering U-Boot.
      #
      # Values:
      #   - nil          - Inactive. Not trying to enter U-Boot.
      #   - :booting     - Rebooting and searching for U-Boot to load.
      #   - :uboot_found - Detected the U-Boot boot stage has started.
      #   - :entering    - Detected the prompt to enter U-Boot and attempting
      #                    to access the U-Boot console.
      :uboot_stage,
      # Ref of the timer that tries to enter the U-Boot console.
      :uboot_prompt_timer,
      # Ref of the timer that tracks the command timeout if U-Boot can't be found.
      :uboot_exipration_timer,
    ]
  end

  @uboot_expiration_in_ms 60_000

  @doc """
  Open a console to a target.

  This function captures `stdin` for the duration of the console connection.

  ## Args
  - `target` - The target to open a console to.
  """
  @spec open(target :: Stingray.Target.t) ::
    :"do not show this result in output"
  def open(target) do
    {:ok, pid} = start_link(target)

    attach(pid)

    GenServer.stop(pid)

    IEx.dont_display_result
  end

  @impl GenServer
  def init(target) do
    serial_device_path =
      case String.starts_with?(target.serial_port, "/") do
        true -> target.serial_port
        _    -> Path.join("/dev", target.serial_port)
      end

    case File.exists?(serial_device_path) do
      false ->
        {:stop, "Serial port not found: `#{serial_device_path}`"}

      _ ->
        state = %State{
          target:             target,
          serial_device_path: serial_device_path,
        }
        |> clear_uboot_state()

        {:ok, state, {:continue, :init}}
    end
  end

  @impl GenServer
  def handle_continue(:init, state) do
    port = di(Port).open(
      {:spawn, "picocom -b #{state.target.baud} #{state.serial_device_path}"},
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
  def handle_call(:uboot, _from, state) when not is_nil(state.uboot_stage) do
    stingray_puts("Already booting to U-Boot")
    {:reply, {:error, :busy}, state}
  end

  @impl GenServer
  def handle_call(:uboot, _from, state) do
    stingray_puts "Launching U-Boot console"

    uboot_exipration_timer =
      Process.send_after(self(), :uboot_timer_expired, @uboot_expiration_in_ms)

    state = %State{
      state |
      uboot_stage:            :booting,
      uboot_exipration_timer: uboot_exipration_timer,
    }

    di(Port).command(state.port, "\n")
    di(Port).command(state.port, "reboot\n")

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:uboot_prompt_timer, state) do
    uboot_console_string = state.target.uboot_console_string || ""
    di(Port).command(state.port, uboot_console_string <> "\n")

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:uboot_timer_expired, state) do
    stingray_puts "U-Boot timed out"

    state = clear_uboot_state(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({_port, {:data, console_data}}, state) do
    IO.write console_data

    line = to_string(console_data)

    state =
      cond do
        state.uboot_stage == :booting && String.match?(line, ~r/^U-Boot /m) ->
          # Use a longer delay if the console string is set, because it's
          # expected that someone will manually enter it or copy/paste it.
          # Autoboot *probably* won't be set to a 0 second delay in this case.
          interval     = if state.target.uboot_console_string, do: 400, else: 150
          {:ok, timer} = :timer.send_interval(interval, :uboot_prompt_timer)

          %State{state | uboot_stage: :uboot_found, uboot_prompt_timer: timer}

        state.uboot_stage == :uboot_found
          && (String.match?(line, ~r/^Hit any key to stop autoboot:/m)
          ||  String.match?(line, ~r/^Autoboot in /m)) ->
            %State{state | uboot_stage: :entering}

        state.uboot_stage == :entering && String.match?(line, ~r/^=>/m) ->
          clear_uboot_state(state)

        state.uboot_stage && String.match?(line, ~r/^Starting kernel \.\.\./m) ->
          stingray_puts "Aborted. U-Boot prompt not detected"
          clear_uboot_state(state)

        true ->
          state
      end

    {:noreply, state}
  end

  defp start_link(target) do
    GenServer.start_link(__MODULE__, target)
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

        :uboot ->
          GenServer.call(pid, :uboot)
      end

    unless result == :break, do: wait_for_input_and_send(port, pid)
  end

  defp stingray_puts(line) do
    IO.puts "\e[0;33m<== #{line} ==>\e[0m"
  end

  defp clear_uboot_state(state) do
    if state.uboot_exipration_timer,
      do: Process.cancel_timer(state.uboot_exipration_timer)

    if state.uboot_prompt_timer,
      do: :timer.cancel(state.uboot_prompt_timer)

    %State{
      state |
      uboot_stage:            nil,
      uboot_prompt_timer:     nil,
      uboot_exipration_timer: nil,
    }
  end
end
