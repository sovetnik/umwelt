defmodule Umwelt.Parser.MacroTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Macro

  test "just variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %{body: "foo", kind: :literal, type: [:Variable]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar" do
    {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

    assert %{body: "bar", kind: :match, term: [:Bar]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{body: "bar", kind: :match, term: [:Bar, :Baz]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{body: "bar", kind: :match, term: [:Foo, :Bar, :Baz]} ==
             Macro.parse(ast, [[:Foo, :Bar]])
  end

  test "defmodule macro" do
    code = """
      defmodule Foo.Bar do
        @moduledoc "Foobar description"
        def foo(bar) do
          :baz
        end
      end
    """

    {:ok, ast} = Code.string_to_quoted(code)

    assert [
             %{
               body: "Bar",
               context: [:Foo, :Bar],
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                   body: "foo",
                   kind: :function
                 }
               ],
               kind: :space,
               note: "Foobar description"
             }
           ] == Macro.parse(ast, [])
  end

  test "def macro" do
    {:ok, ast} =
      """
        def div do
          :foo
        end
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [],
             body: "div",
             kind: :function
           } == Macro.parse(ast, [])
  end

  test "= macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

    assert %{body: "msg", kind: :match, term: [:Foo]} == Macro.parse(ast, [])
  end

  test "% macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert [:Foo] == Macro.parse(ast, [])
  end

  test "tuple macro" do
    {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "one", kind: :literal, type: [:Variable]},
               [%{body: "two", kind: :literal, type: [:Atom]}]
             ]
           } == Macro.parse(ast, [[:Foo, :Bar]])
  end
end
