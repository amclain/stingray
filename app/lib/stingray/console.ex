defmodule Stingray.Console do
  @moduledoc """
  Interact with a hardware target.

  ## Console commands

  Console commands start with `#` followed by a keyword. They are available
  when attached to the console of a target.

  - `#cycle`  - Cycle the target's power off and on.
  - `#exit`   - Close the console to the target.
  - `#off`    - Turn off power to the target.
  - `#on`     - Turn on power to the target.
  - `#power?` - Check if the target's power is on or off.
  - `#q`      - Close the console to the target.
  """

  alias Stingray.Target

  @doc """
  Open a console to a target given its ID or `Stingray.Target` struct.

  This function captures `stdin` for the duration of the console connection.
  """
  @spec open(target :: atom | Target.t) :: :"do not show this result in output"
  def open(target_id) when is_atom(target_id) and not is_nil(target_id) do
    case Target.get(target_id) do
      nil    -> puts_error("Target `#{target_id}` not found")
      target -> open(target)
    end

    IEx.dont_display_result
  end

  def open(target = %Target{}) do
    Stingray.Console.Server.open(target)

    IEx.dont_display_result
  end

  defp puts_error(message) do
    IO.puts "\e[0;31m#{message}\e[0m"
  end
end
