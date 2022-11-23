defmodule Stringray.Test do
  use ESpec

  it "delegates a function to open a console to a target" do
    allow Stingray.Console |> to(accept :open, fn target ->
      expect target |> to(eq :my_target)
      :ok
    end)

    expect Stingray.console(:my_target) |> to(eq :ok)

    expect Stingray.Console |> to(accepted :open)
  end
end
