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
               type: %{kind: :Literal, type: :anything}
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 kind: :Value,
                 keyword: [],
                 type: %{name: :Bar, path: [:Bar], kind: :Alias}
               }
             } == Macro.parse(ast, [])
    end

    test "typed variable Bar.Baz" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 kind: :Value,
                 type: %{name: :Baz, path: [:Bar, :Baz], kind: :Alias},
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
                 kind: :Value,
                 type: %{name: :Baz, path: [:Foo, :Bar, :Baz], kind: :Alias},
                 keyword: []
               }
             } == Macro.parse(ast, [%{name: :Bar, path: [:Foo, :Bar], kind: :Alias}])
    end
  end

  describe "sigil macro examples" do
    test "sigil W" do
      {:ok, ast} = Code.string_to_quoted("~w|foo bar|a")

      assert %{body: "foo bar", kind: :Sigil, note: "sigil_w|a"} == Parser.parse(ast, [])
    end
  end

  describe "other macro examples" do
    test "pipe list head | tail" do
      {:ok, ast} = Code.string_to_quoted("head | tail")

      assert %{
               body: "|",
               kind: :Pipe,
               left: %{type: %{type: :anything, kind: :Literal}, body: "head", kind: :Variable},
               right: [%{type: %{type: :anything, kind: :Literal}, body: "tail", kind: :Variable}]
             } == Parser.parse(ast, [])
    end

    test "defmodule macro" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
            @moduledoc "Foobar description"
            def foo(bar) do
              :baz
            end
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Bar",
                 context: ["Foo", "Bar"],
                 attrs: [],
                 calls: [],
                 guards: [],
                 types: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable}
                     ],
                     body: "foo",
                     kind: :Function
                   }
                 ],
                 kind: :Concept,
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
               kind: :Function
             } == Macro.parse(ast, [])
    end

    test "match macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

      assert %{
               body: "msg",
               kind: :Match,
               term: %{
                 kind: :Value,
                 type: %{name: :Foo, path: [:Foo], kind: :Alias},
                 keyword: []
               }
             } == Macro.parse(ast, [])
    end

    test "struct macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{}")

      assert %{
               keyword: [],
               kind: :Value,
               type: %{name: :Foo, path: [:Foo], kind: :Alias}
             } == Macro.parse(ast, [])
    end

    test "tuple macro" do
      {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

      assert %{
               kind: :Value,
               type: %{kind: :Structure, type: :tuple},
               elements: [
                 %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
                 %{body: "one", kind: :Variable, type: %{kind: :Literal, type: :anything}},
                 %{
                   type: %{kind: :Structure, type: :list},
                   values: [%{type: %{kind: :Literal, type: :atom}, body: "two", kind: :Value}],
                   kind: :Value
                 }
               ]
             } == Macro.parse(ast, [[:Foo, :Bar]])
    end
  end

  describe "skipped macros" do
    test "unquote" do
      {:ok, ast} = Code.string_to_quoted("unquote(name)(opts)")

      assert %{unquoted: []} == Macro.parse(ast, [])
    end
  end
end
