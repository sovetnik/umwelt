defmodule Umwelt.Parser.TripleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Triple

  test "just variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %{:body => "foo", :kind => [:Undefined]} ==
             Triple.parse(ast, [])
  end

  test "typed variable Bar" do
    {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

    assert %{:body => "bar", :match => [:Bar]} ==
             Triple.parse(ast, [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{:body => "bar", :match => [:Bar, :Baz]} ==
             Triple.parse(ast, [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

    assert %{:body => "bar", :match => [:Foo, :Bar, :Baz]} ==
             Triple.parse(ast, [[:Foo, :Bar]])
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
                 %{body: "bar", kind: [:Undefined]}
               ],
               method: :foo
             },
             %{
               context: [:Foo, :Bar],
               moduledoc: ["Foobar description"]
             }
           ] == Triple.parse(ast, [])
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
             method: :div
           } == Triple.parse(ast, [])
  end

  test "= triple" do
    {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

    assert %{body: "msg", match: [:Foo]} == Triple.parse(ast, [])
  end

  test "% triple" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert [:Foo] == Triple.parse(ast, [])
  end

  test "tuple triple" do
    {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

    assert %{
             tuple: [
               %{body: "ok", kind: [:Atom]},
               %{body: "one", kind: [:Undefined]},
               [%{body: "two", kind: [:Atom]}]
             ]
           } == Triple.parse(ast, [[:Foo, :Bar]])
  end
end
