defmodule Umwelt.Parser.MacroTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser
  alias Umwelt.Parser.Macro

  import Umwelt.Parser.Macro,
    only: [
      is_atom_macro: 1,
      is_macro_macro: 1,
      is_macro: 1
    ]

  describe "macro guards" do
    test "guard is_macro" do
      [
        {:foo, [], nil},
        {:bar, [], []},
        {{:foo, [], nil}, [], []},
        {{:foo, [], []}, [], []}
      ]
      |> Enum.map(&assert is_macro(&1))
    end

    test "guard is_atom_macro" do
      [{:foo, [], nil}, {:bar, [], []}]
      |> Enum.map(&assert is_atom_macro(&1))
    end

    test "guard is_macro_macro" do
      [
        {{:foo, [], nil}, [], []},
        {{:foo, [], []}, [], []}
      ]
      |> Enum.map(&assert is_macro_macro(&1))
    end
  end

  describe "parse variables" do
    test "just variable" do
      {:ok, ast} = Code.string_to_quoted("foo")

      assert %{
               body: "foo",
               kind: :Variable,
               type: [:Variable]
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 context: [:Bar],
                 kind: :Value,
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar.Baz" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 context: [:Bar, :Baz],
                 kind: :Value,
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar.Baz aliased" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 context: [:Foo, :Bar, :Baz],
                 kind: :Value,
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [[:Foo, :Bar]])
    end
  end

  describe "other macro examples" do
    test "pipe list head | tail" do
      {:ok, ast} = Code.string_to_quoted("head | tail")

      assert %{
               body: "|",
               kind: :Pipe,
               values: [
                 %{type: [:Variable], body: "head", kind: :Variable},
                 %{type: [:Variable], body: "tail", kind: :Variable}
               ]
             } == Parser.parse(ast, [])
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
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :Variable}],
                     body: "foo",
                     kind: :Call
                   }
                 ],
                 kind: :Space,
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
               kind: :Call
             } == Macro.parse(ast, [])
    end

    test "match macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

      assert %{
               body: "msg",
               kind: :Match,
               term: %{
                 context: [:Foo],
                 kind: :Value,
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "struct macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{}")

      assert %{context: [:Foo], kind: :Value, type: [:Map], keyword: []} == Macro.parse(ast, [])
    end

    test "tuple macro" do
      {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

      assert %{
               kind: :Value,
               type: [:Tuple],
               elements: [
                 %{body: "ok", kind: :Value, type: [:Atom]},
                 %{body: "one", kind: :Variable, type: [:Variable]},
                 [%{body: "two", kind: :Value, type: [:Atom]}]
               ]
             } == Macro.parse(ast, [[:Foo, :Bar]])
    end
  end
end
