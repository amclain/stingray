defmodule Stingray.PowerManager do
  @moduledoc """
  Manages the power supplied to a target.
  """

  @doc """
  Start a power manager.
  """
  @callback start_link(opts :: term) :: GenServer.on_start

  @doc """
  Cycle a target's power off and on.

  Issuing an on or off command will cancel the power cycle.
  """
  @callback cycle(cycle_time_in_ms :: non_neg_integer) :: :ok

  @doc """
  Returns `true` if power is being supplied to the target.
  """
  @callback power?() :: boolean

  @doc """
  Turn on power to the target.
  """
  @callback on() :: :ok

  @doc """
  Turn off power to the target.
  """
  @callback off() :: :ok

  use Resolve

  defmacro __using__(_) do
    quote do
      @behaviour Stingray.PowerManager
    end
  end

  @doc false
  def child_spec(opts), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  def start_link(opts), do: resolve(__MODULE__).start_link(opts)

  def cycle(cycle_time_in_ms \\ 2000), do: resolve(__MODULE__).cycle(cycle_time_in_ms)

  def power?, do: resolve(__MODULE__).power?

  def on, do: resolve(__MODULE__).on

  def off, do: resolve(__MODULE__).off
end
