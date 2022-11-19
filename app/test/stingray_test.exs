defmodule StingrayTest do
  use ExUnit.Case
  doctest Stingray

  test "greets the world" do
    assert Stingray.hello() == :world
  end
end
