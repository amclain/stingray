defmodule Stingray.PowerManager do
  @moduledoc """
  Manages the power supplied to a target.
  """

  @doc """
  Start a power manager.
  """
  @callback start_link(opts :: term) :: GenServer.on_start

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

  use DI

  defmacro __using__(_) do
    quote do
      @behaviour Stingray.PowerManager
    end
  end

  @doc false
  def child_spec(opts), do: %{id: di(__MODULE__), start: {di(__MODULE__), :start_link, [opts]}}

  def start_link(opts), do: di(__MODULE__).start_link(opts)

  def power?, do: di(__MODULE__).power?

  def on, do: di(__MODULE__).on

  def off, do: di(__MODULE__).off
end
