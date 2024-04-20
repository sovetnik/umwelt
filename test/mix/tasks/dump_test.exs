defmodule Mix.Tasks.DumpTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Dump

  test "dump parsed ast in umwelt.bin by default" do
    assert :ok = Dump.run([])

    {:ok, bin} = File.read("umwelt.bin")

    assert %{} = :erlang.binary_to_term(bin)

    File.rm("umwelt.bin")
  end

  test "dump parsed ast into given filename" do
    assert :ok = Dump.run(["dump.bin"])

    {:ok, bin} = File.read("dump.bin")

    assert %{} = :erlang.binary_to_term(bin)

    File.rm("dump.bin")
  end
end
