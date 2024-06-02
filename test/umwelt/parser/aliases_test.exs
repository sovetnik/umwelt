defmodule Umwelt.Parser.AliasesTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Aliases

  test "parse single alias" do
    {:ok, ast} =
      """
      alias Foo.Bar
      """
      |> Code.string_to_quoted()

    assert %{kind: :Alias, name: :Bar, path: [:Foo, :Bar]} == Aliases.parse(ast, [])
  end

  test "parse single named alias" do
    {:ok, ast} =
      """
      alias Estructura.Config, as: Cfg
      """
      |> Code.string_to_quoted()

    assert %{kind: :Alias, name: [:Cfg], path: [:Estructura, :Config]} == Aliases.parse(ast, [])
  end

  test "parse multi alias" do
    {:ok, ast} =
      """
      alias Foo.{Bar, Baz}
      """
      |> Code.string_to_quoted()

    assert [
             %{name: :Bar, path: [:Foo, :Bar], kind: :Alias},
             %{name: :Baz, path: [:Foo, :Baz], kind: :Alias}
           ] == Aliases.parse(ast, [])
  end

  describe "expandind modules via aliases" do
    test "nothing to expand" do
      module = [:Foo]
      aliases = []
      assert [:Foo] == Aliases.expand_module(module, aliases)
    end

    test "aliases not match" do
      module = [:Foo, :Bar]
      aliases = [%{kind: :Alias, name: :Baz, path: [:Bar, :Baz]}]
      assert module == Aliases.expand_module(module, aliases)
    end

    test "aliases match and module expanded" do
      module = [:Bar, :Baz]
      aliases = [%{kind: :Alias, name: :Bar, path: [:Foo, :Bar]}]
      assert [:Foo, :Bar, :Baz] == Aliases.expand_module(module, aliases)
    end
  end
end
