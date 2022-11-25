defmodule Stingray.Console.Server.Test do
  use ESpec

  alias Stingray.Console.Server

  it "can open a console server" do
    DI.inject(Port, quote do
      def open(_name, _opts), do: self()

      def close(_port), do: :ok

      def command(_port, _data), do: :ok
    end)

    DI.inject(IO, quote do
      def gets(_), do: "#exit\n"
    end)

    allow File |> to(accept :exists?, fn "/dev/ttyTest0" -> true end)

    output = capture_io(fn ->
      expect Server.open("/dev/ttyTest0", 115200)
      |> to(eq :"do not show this result in output")
    end)

    expect output |> to(have "Console closed")

    expect File |> to(accepted :exists?)
  end
end
