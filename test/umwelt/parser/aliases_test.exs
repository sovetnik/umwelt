defmodule Umwelt.Parser.AliasesTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.Alias
  alias Umwelt.Parser.Aliases

  describe "parse in context" do
    test "parse single alias" do
      {:ok, ast} =
        """
        alias Foo.Bar
        """
        |> Code.string_to_quoted()

      assert %Alias{name: "Bar", path: ["Foo", "Bar"]} == Aliases.parse(ast, [], ["Woo"])
    end

    test "parse single named alias" do
      {:ok, ast} =
        """
        alias Estructura.Config, as: Cfg
        """
        |> Code.string_to_quoted()

      assert %Alias{name: "Cfg", path: ["Estructura", "Config"]} ==
               Aliases.parse(ast, [], ["Woo"])
    end

    test "parse multi alias" do
      {:ok, ast} =
        """
        alias Foo.{Bar, Baz}
        """
        |> Code.string_to_quoted()

      assert [
               %Alias{name: "Bar", path: ["Foo", "Bar"]},
               %Alias{name: "Baz", path: ["Foo", "Baz"]}
             ] == Aliases.parse(ast, [], ["Woo"])
    end

    test "parse multi alias and _module_" do
      {:ok, ast} =
        """
        alias __MODULE__.Foo.{Bar, Baz}
        """
        |> Code.string_to_quoted()

      assert [
               %Alias{name: "Bar", path: ["Woo", "Foo", "Bar"]},
               %Alias{name: "Baz", path: ["Woo", "Foo", "Baz"]}
             ] == Aliases.parse(ast, [], ["Woo"])
    end
  end

  describe "full module path" do
    test "nothing to expand" do
      module = [:Foo]
      aliases = []
      assert ["Foo"] == Aliases.full_path(module, aliases, ["Woo"])
    end

    test "aliases not match" do
      module = [:Foo, :Bar]
      aliases = [%Alias{name: "Baz", path: ["Bar", "Baz"]}]
      assert ["Foo", "Bar"] == Aliases.full_path(module, aliases, ["Woo"])
    end

    test "aliases match and module expanded" do
      module = [:Bar, :Baz]
      aliases = [%Alias{name: "Bar", path: ["Foo", "Bar"]}]
      assert ["Foo", "Bar", "Baz"] == Aliases.full_path(module, aliases, ["Woo"])
    end

    test "module expanded with context" do
      module = [{:__MODULE__, [], nil}, :Bar, :Baz]
      aliases = [%Alias{name: "Bar", path: ["Foo", "Bar"]}]
      assert ["Woo", "Bar", "Baz"] == Aliases.full_path(module, aliases, ["Woo"])
    end
  end
end
