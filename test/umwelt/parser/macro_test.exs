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
               kind: :variable,
               type: [:Variable]
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: %{
                 context: [:Bar],
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar.Baz" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: %{
                 context: [:Bar, :Baz],
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar.Baz aliased" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: %{
                 context: [:Foo, :Bar, :Baz],
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
               kind: :pipe,
               values: [
                 %{type: [:Variable], body: "head", kind: :variable},
                 %{type: [:Variable], body: "tail", kind: :variable}
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
                     arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                     body: "foo",
                     kind: :call
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
               kind: :call
             } == Macro.parse(ast, [])
    end

    test "match macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

      assert %{
               body: "msg",
               kind: :match,
               term: %{
                 context: [:Foo],
                 type: [:Map],
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "struct macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{}")

      assert %{context: [:Foo], type: [:Map], keyword: []} == Macro.parse(ast, [])
    end

    test "tuple macro" do
      {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

      assert %{
               type: [:Tuple],
               elements: [
                 %{body: "ok", kind: :value, type: [:Atom]},
                 %{body: "one", kind: :variable, type: [:Variable]},
                 [%{body: "two", kind: :value, type: [:Atom]}]
               ]
             } == Macro.parse(ast, [[:Foo, :Bar]])
    end
  end
end
