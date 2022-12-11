defmodule Stingray.PowerManager do
  @moduledoc """
  Manages the power supplied to a target.
  """

  use GenServer
  use DI

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

  @doc """
  Start a power manager.
  """
  @spec start_link(args :: nil) :: GenServer.on_start
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Turn off power to the target.
  """
  @spec off() :: :ok
  def off do
    GenServer.call(__MODULE__, :off)
  end

  @doc """
  Turn on power to the target.
  """
  @spec on() :: :ok
  def on do
    GenServer.call(__MODULE__, :on)
  end

  @doc """
  Returns `true` if power is being supplied to the target.
  """
  @spec power?() :: boolean
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
