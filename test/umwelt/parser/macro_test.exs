defmodule Umwelt.Parser.MacroTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Macro

  test "just variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %{:body => "foo", :kind => [:Variable]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar" do
    {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

    assert %{:body => "bar", :match => [:Bar]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{:body => "bar", :match => [:Bar, :Baz]} ==
             Macro.parse(ast, [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{:body => "bar", :match => [:Foo, :Bar, :Baz]} ==
             Macro.parse(ast, [[:Foo, :Bar]])
  end

  test "defmodule triple" do
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
               args: [
                 %{body: "bar", kind: [:Variable]}
               ],
               function: :foo
             },
             %{
               context: [:Foo, :Bar],
               moduledoc: ["Foobar description"]
             }
           ] == Macro.parse(ast, [])
  end

  test "def triple" do
    {:ok, ast} =
      """
        def div do
          :foo
        end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [],
             function: :div
           } == Macro.parse(ast, [])
  end

  test "= triple" do
    {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

    assert %{body: "msg", match: [:Foo]} == Macro.parse(ast, [])
  end

  test "% triple" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert [:Foo] == Macro.parse(ast, [])
  end

  test "tuple triple" do
    {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

    assert %{
             tuple: [
               %{body: "ok", kind: [:Atom]},
               %{body: "one", kind: [:Variable]},
               [%{body: "two", kind: [:Atom]}]
             ]
           } == Macro.parse(ast, [[:Foo, :Bar]])
  end
end
