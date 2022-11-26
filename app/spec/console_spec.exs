defmodule Stingray.Console.Test do
  use ESpec

  alias Stingray.Console
  alias Stingray.Target

  let :target_number,      do: 1
  let :target_id,          do: :my_target
  let :target_name,        do: "My Target"
  let :target_serial_port, do: "ttyBogus0"
  let :target_baud,        do: 115200

  before do
    {:ok, target} = Target.add(
      target_number(),
      target_id(),
      target_name(),
      target_serial_port(),
      target_baud()
    )

    {:shared, target: target}
  end

  it "can open a console by target ID" do
    allow Stingray.Console.Server |> to(accept :open, fn target ->
      expect target |> to(eq shared.target)

      :"do not show this result in output"
    end)

    expect Console.open(target_id()) |> to(eq :"do not show this result in output")

    expect Stingray.Console.Server |> to(accepted :open)
  end

  it "can open a console with a target handle" do
    allow Stingray.Console.Server |> to(accept :open, fn target ->
      expect target |> to(eq shared.target)

      :"do not show this result in output"
    end)

    expect Console.open(shared.target) |> to(eq :"do not show this result in output")

    expect Stingray.Console.Server |> to(accepted :open)
  end

  it "prints an error if target ID is not found" do
    allow Stingray.Console.Server |> to(accept :open, fn _target -> nil end)
    
    allow IO |> to(accept :puts, fn line ->
      expect line |> to(eq "\e[0;31mTarget `bogus_target` not found\e[0m")
      :ok
    end)

    expect Console.open(:bogus_target) |> to(eq :"do not show this result in output")

    expect IO |> to(accepted :puts)
    expect Stingray.Console.Server |> to_not(accepted :open)
  end
end
