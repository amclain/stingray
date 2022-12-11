defmodule Stingray.PowerManager.Test do
  use ESpec

  alias Stingray.PowerManager

  before do
    DI.inject(Circuits.GPIO, quote do
      def open(_pin, :output, [initial_value: 1]),
        do: {:ok, self()}

      def open(_pin, _direction, _opts),
        do: raise "Unexpected args for Circuits.GPIO.open"

      def write(_pin, _value), do: :ok
    end)

    {:ok, power_manager} = PowerManager.start_link(nil)

    {:shared, power_manager: power_manager}
  end

  finally do
    if Process.alive?(shared.power_manager),
      do: GenServer.stop(shared.power_manager)
  end

  it "can turn power to the target on and off" do
    expect PowerManager.power? |> to(eq false)

    :ok = PowerManager.on
    expect PowerManager.power? |> to(eq true)

    :ok = PowerManager.off
    expect PowerManager.power? |> to(eq false)
  end
end
