defmodule Mix.Tasks.DumpTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Mix.Tasks.Umwelt.Dump

  describe "parse([root_name])" do
    test "parse app from Mix.Project.config by default" do
      assert capture_io([], fn ->
               assert :ok == Dump.run([])
             end) =~ "Parsing result saved into umwelt.bin"

      {:ok, bin} = File.read("umwelt.bin")

      assert %{} = :erlang.binary_to_term(bin)

      File.rm("umwelt.bin")
    end

    test "parse app from given root_name" do
      assert capture_io([], fn ->
               assert :ok == Dump.run(["umwelt"])
             end) =~ "Parsing result saved into umwelt.bin"

      {:ok, bin} = File.read("umwelt.bin")

      assert %{} = :erlang.binary_to_term(bin)

      File.rm("umwelt.bin")
    end
  end
end
