defmodule Stringray.Test do
  use ESpec

  specify do: expect true |> to(eq true)
end
