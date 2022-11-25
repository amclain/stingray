defmodule Stingray.Console.CommandParser.Test do
  use ESpec

  alias Stingray.Console.CommandParser

  it "passes through non-commands" do
    expect CommandParser.parse("this is not a command\n")
    |> to(eq :passthrough)

    expect CommandParser.parse("#this is not a command\n")
    |> to(eq :passthrough)
  end

  specify "exit" do
    expect CommandParser.parse("#exit\n") |> to(eq :exit)
    expect CommandParser.parse("#q\n")    |> to(eq :exit)
  end
end
