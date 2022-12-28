defmodule Stingray.PowerManager.Driver.Test do
  use ESpec

  alias Stingray.PowerManager

  before do
    test_pid = self()

    Resolve.inject(Stingray.PowerManager, Stingray.PowerManager.Driver)

    Resolve.inject(Circuits.GPIO, quote do
      def open(_pin, :output, [initial_value: 1]),
        do: {:ok, self()}

      def open(_pin, _direction, _opts),
        do: raise "Unexpected args for Circuits.GPIO.open"

      def write(_pin, value) do
        send(unquote(test_pid), {:gpio, :write, value})
        :ok
      end
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

  describe "cycle" do
    it "turns a target's power off and on if the power is already on" do
      :ok = PowerManager.on
      expect PowerManager.power? |> to(eq true)
      assert_received {:gpio, :write, 0}

      :ok = PowerManager.cycle(1)
      :timer.sleep(5)
      expect PowerManager.power? |> to(eq true)

      assert_receive {:gpio, :write, 1}
      assert_receive {:gpio, :write, 0}
    end

    it "immediately turns a target's power on if the power is off" do
      :ok = PowerManager.off
      expect PowerManager.power? |> to(eq false)
      assert_received {:gpio, :write, 1}

      :ok = PowerManager.cycle(30)
      expect PowerManager.power? |> to(eq true)

      refute_receive {:gpio, :write, 1}
      assert_receive {:gpio, :write, 0}
    end

    it "cancels the cycle if power on is called" do
      :ok = PowerManager.on
      expect PowerManager.power? |> to(eq true)
      assert_received {:gpio, :write, 0}

      :ok = PowerManager.cycle(10)
      assert_received {:gpio, :write, 1}

      :ok = PowerManager.on
      assert_received {:gpio, :write, 0}
      refute_receive {:gpio, :write, 0}
    end

    it "cancels the cycle if power off is called" do
      :ok = PowerManager.on
      expect PowerManager.power? |> to(eq true)
      assert_received {:gpio, :write, 0}

      :ok = PowerManager.cycle(10)
      assert_received {:gpio, :write, 1}

      :ok = PowerManager.off
      assert_received {:gpio, :write, 1}
      refute_receive {:gpio, :write, 0}
    end
  end
end
