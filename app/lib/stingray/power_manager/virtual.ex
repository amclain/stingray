defmodule Stingray.PowerManager.Virtual do
  @moduledoc """
  A stub for when power management hardware is not available.
  """

  use GenServer
  use Stingray.PowerManager

  @impl Stingray.PowerManager
  def power?, do: true
  
  @impl Stingray.PowerManager
  def on, do: :ok

  @impl Stingray.PowerManager
  def off, do: :ok

  @impl Stingray.PowerManager
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, nil}
  end
end
