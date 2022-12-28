defmodule Stingray.PowerManager.Driver do
  @moduledoc """
  Manages the hardware for supplying power to a target.
  """

  use GenServer
  use Resolve
  use Stingray.PowerManager

  defmodule State do
    @moduledoc false

    defstruct [
      # Ref of the timer for cycling power.
      :cycle_timer,
      # Handle to the Circuits.GPIO pin.
      :gpio_pin,
      # True if power is being supplied to the target by the power manager.
      :is_on,
    ]
  end

  @relay_pin Application.compile_env!(:stingray, :io).relay_pin

  @impl Stingray.PowerManager
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Stingray.PowerManager
  def cycle(cycle_time_in_ms) do
    GenServer.call(__MODULE__, {:cycle, cycle_time_in_ms})
  end

  @impl Stingray.PowerManager
  def off do
    GenServer.call(__MODULE__, :off)
  end

  @impl Stingray.PowerManager
  def on do
    GenServer.call(__MODULE__, :on)
  end

  @impl Stingray.PowerManager
  def power? do
    GenServer.call(__MODULE__, :power?)
  end

  @impl GenServer
  def init(_) do
    {:ok, nil, {:continue, :init}}
  end

  @impl GenServer
  def handle_continue(:init, _state) do
    {:ok, gpio_pin} =
      resolve(Circuits.GPIO).open(@relay_pin, :output, initial_value: 0)

    state = %State{
      cycle_timer: nil,
      gpio_pin:    gpio_pin,
      is_on:       false,
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:cycle, _cycle_time_in_ms}, from, state) when not state.is_on,
    do: handle_call(:on, from, state)

  def handle_call({:cycle, cycle_time_in_ms}, _from, state) do
    :ok = resolve(Circuits.GPIO).write(state.gpio_pin, 0)

    cycle_timer = Process.send_after(self(), :cycle_timer, cycle_time_in_ms)
    state       = %State{state | is_on: false, cycle_timer: cycle_timer}

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:power?, _from, state) do
    {:reply, state.is_on, state}
  end

  @impl GenServer
  def handle_call(:on, _from, state) do
    if state.cycle_timer,
      do: Process.cancel_timer(state.cycle_timer)

    :ok = resolve(Circuits.GPIO).write(state.gpio_pin, 1)

    {:reply, :ok, %State{state | is_on: true, cycle_timer: nil}}
  end

  @impl GenServer
  def handle_call(:off, _from, state) do
    if state.cycle_timer,
      do: Process.cancel_timer(state.cycle_timer)

    :ok = resolve(Circuits.GPIO).write(state.gpio_pin, 0)

    {:reply, :ok, %State{state | is_on: false, cycle_timer: nil}}
  end

  @impl GenServer
  def handle_info(:cycle_timer, state) do
    :ok   = resolve(Circuits.GPIO).write(state.gpio_pin, 1)
    state = %State{state | is_on: true, cycle_timer: nil}

    {:noreply, state}
  end
end
