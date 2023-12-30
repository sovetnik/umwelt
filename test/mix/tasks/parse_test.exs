defmodule Mix.Tasks.ParseTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Parse

  test "parsed ast in map" do
    assert :ok = Parse.run([])
  end
end
