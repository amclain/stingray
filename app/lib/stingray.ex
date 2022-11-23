defmodule Stingray do
  @moduledoc """
  Build farm automation and remote management.
  """

  defdelegate console(target), to: Stingray.Console, as: :open
end
