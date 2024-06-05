defmodule Mix.Tasks.DumpTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Dump

  describe "parse([root_name])" do
    test "parse app from Mix.Project.config by default" do
      assert :ok = Dump.run([])

      {:ok, bin} = File.read("umwelt.bin")

      assert %{} = :erlang.binary_to_term(bin)

      File.rm("umwelt.bin")
    end

    test "parse app from given root_name" do
      assert :ok = Dump.run(["umwelt"])

      {:ok, bin} = File.read("umwelt.bin")

      assert %{} = :erlang.binary_to_term(bin)

      File.rm("umwelt.bin")
    end
  end
end
