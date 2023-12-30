defmodule UmweltTest do
  use ExUnit.Case
  doctest Umwelt

  test "greets the world" do
    assert Umwelt.hello() == :world
  end
end
