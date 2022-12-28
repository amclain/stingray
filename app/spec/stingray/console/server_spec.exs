defmodule Stingray.Console.Server.Test do
  use ESpec

  alias Stingray.Target
  alias Stingray.Console.Server

  it "can open a console server" do
    Resolve.inject(Port, quote do
      def open(_name, _opts), do: self()

      def close(_port), do: :ok

      def command(_port, _data), do: :ok
    end)

    Resolve.inject(IO, quote do
      def gets(_), do: "#exit\n"
    end)

    allow File |> to(accept :exists?, fn "/dev/ttyTest0" -> true end)

    {:ok, target} = Target.add(1, :test_target, "Test target", "ttyTest0", 115200)

    output = capture_io(fn ->
      expect Server.open(target)
      |> to(eq :"do not show this result in output")
    end)

    expect output |> to(have "Console closed")

    expect File |> to(accepted :exists?)
  end
end
