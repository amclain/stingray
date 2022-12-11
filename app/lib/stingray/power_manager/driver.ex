defmodule Stingray.PowerManager.Driver do
  @moduledoc """
  Manages the hardware for supplying power to a target.
  """

  use GenServer
  use DI
  use Stingray.PowerManager

  defmodule State do
    @moduledoc false

    defstruct [
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
    {:ok, gpio_pin} = di(Circuits.GPIO).open(@relay_pin, :output, initial_value: 1)

    state = %State{
      gpio_pin: gpio_pin,
      is_on:    false,
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:power?, _from, state) do
    {:reply, state.is_on, state}
  end

  @impl GenServer
  def handle_call(:on, _from, state) do
    :ok = di(Circuits.GPIO).write(state.gpio_pin, 0)

    {:reply, :ok, %State{state | is_on: true}}
  end

  @impl GenServer
  def handle_call(:off, _from, state) do
    :ok = di(Circuits.GPIO).write(state.gpio_pin, 1)

    {:reply, :ok, %State{state | is_on: false}}
  end
end
