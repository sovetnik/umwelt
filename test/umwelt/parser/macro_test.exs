defmodule Umwelt.Parser.MacroTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Call,
    Concept,
    Function,
    Literal,
    Operator,
    Sigil,
    Structure,
    Value,
    Variable
  }

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

      assert %Variable{body: "foo", type: %Literal{type: :anything}} ==
               Macro.parse(ast, [], [])
    end

    test "typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %Operator{
               left: %Structure{type: %Alias{name: "Bar", path: ["Foo", "Bar"]}, elements: []},
               name: "match",
               right: %Variable{body: "bar", type: %Literal{type: :anything}}
             } == Macro.parse(ast, [%Alias{name: "Bar", path: ["Foo", "Bar"]}], [])
    end

    test "typed variable Bar.Baz" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %Operator{
               left: %Structure{type: %Alias{name: "Baz", path: ["Bar", "Baz"]}, elements: []},
               name: "match",
               right: %Variable{body: "bar", type: %Literal{type: :anything}}
             } == Macro.parse(ast, [], [])
    end

    test "typed variable Bar.Baz aliased" do
      {:ok, ast} = Code.string_to_quoted("%Bar.Baz{} = bar")

      assert %Operator{
               left: %Structure{type: %Alias{name: "Baz", path: ["Foo", "Bar", "Baz"]}},
               name: "match",
               right: %Variable{body: "bar", type: %Literal{type: :anything}}
             } == Macro.parse(ast, [%{name: "Bar", path: ["Foo", "Bar"], kind: :Alias}], [])
    end
  end

  describe "sigil macro examples" do
    test "sigil W" do
      {:ok, ast} = Code.string_to_quoted("~w|foo bar|a")

      assert %Sigil{string: "foo bar", mod: "sigil_w|a"} == Parser.parse(ast, [], [])
    end
  end

  describe "other macro examples" do
    test "pipe list head | tail" do
      {:ok, ast} = Code.string_to_quoted("head | tail")

      assert %Operator{
               left: %Variable{body: "head", type: %Literal{type: :anything}},
               right: %Variable{body: "tail", type: %Literal{type: :anything}},
               name: "alter"
             } == Parser.parse(ast, [], [])
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     }
                   }
                 ],
                 note: "Foobar description"
               }
             ] == Macro.parse(ast, [], [])
    end

    test "def macro" do
      {:ok, ast} =
        """
          def div do
            :foo
          end
        """
        |> Code.string_to_quoted()

      assert %Function{body: %Call{name: "div", type: %Literal{type: :anything}}} ==
               Macro.parse(ast, [], [])
    end

    test "match macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{} = msg")

      assert %Operator{
               name: "match",
               left: %Structure{type: %Alias{name: "Foo", path: ["Foo"]}, elements: []},
               right: %Variable{body: "msg", type: %Umwelt.Felixir.Literal{type: :anything}}
             } == Macro.parse(ast, [], [])
    end

    test "struct macro" do
      {:ok, ast} = Code.string_to_quoted("%Foo{}")

      assert %Structure{type: %Alias{name: "Foo", path: ["Foo"]}, elements: []} ==
               Macro.parse(ast, [], [])
    end

    test "tuple macro" do
      {:ok, ast} = Code.string_to_quoted("{:ok, one, [:two]}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Variable{body: "one", type: %Literal{type: :anything}},
                 %Structure{
                   type: %Literal{type: :list},
                   elements: [%Value{type: %Literal{type: :atom}, body: "two"}]
                 }
               ]
             } == Macro.parse(ast, [[:Foo, :Bar]], [])
    end
  end

  describe "skipped macros" do
    test "unquote" do
      {:ok, ast} = Code.string_to_quoted("unquote(name)(opts)")

      assert %{unquoted: []} == Macro.parse(ast, [], [])
    end
  end
end
