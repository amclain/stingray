defmodule Stingray.PowerManager.Vritual.Test do
  use ESpec

  alias Stingray.PowerManager

  before do
    DI.inject(Stingray.PowerManager, Stingray.PowerManager.Virtual)
  end

  it "target power always appears on" do
    expect PowerManager.power? |> to(eq true)

    :ok = PowerManager.on
    expect PowerManager.power? |> to(eq true)

    :ok = PowerManager.off
    expect PowerManager.power? |> to(eq true)
  end
end
