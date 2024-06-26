defmodule Stingray.Console.CommandParser do
  @moduledoc """
  Parses console commands.
  """

  @doc """
  Parse a line from Stingray's stdin and look for a special command.

  Returns `:passthrough` if a command was not found.
  """
  @spec parse(line :: String.t) ::
      :passthrough
    | :exit
    | {:power, :cycle | :is_on? | :off | :on}
    | :uboot
  def parse(line) when is_binary(line) do
    case String.starts_with?(line, "#") do
      false -> :passthrough
      _     -> line |> String.slice(1..-2) |> do_parse()
    end
  end

  defp do_parse("cycle"),        do: {:power, :cycle}
  defp do_parse("exit"),         do: :exit
  defp do_parse("off"),          do: {:power, :off}
  defp do_parse("on"),           do: {:power, :on}
  defp do_parse("power?"),       do: {:power, :is_on?}
  defp do_parse("q"),            do: :exit
  defp do_parse("uboot"),        do: :uboot
  defp do_parse(_not_a_command), do: :passthrough
end
