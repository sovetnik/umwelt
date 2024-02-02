defmodule Umwelt.Parser.ComparisonTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Comparison

  import Umwelt.Parser.Comparison,
    only: [
      is_comparison: 1,
      is_comparison_operator: 1,
      is_relaxed_bool_comparison: 1,
      is_strict_bool_comparison: 1
    ]

  describe "guards" do
    test "guard is_comparison" do
      [:==, :&&, :and, :not, :in]
      |> Enum.map(&assert is_comparison(&1))
    end

    test "guard is_comparison_operator" do
      [:==, :!=, :===, :!==, :<, :<=, :>, :>=]
      |> Enum.map(&assert is_comparison_operator(&1))
    end

    test "guard is_strict_bool_comparison" do
      [:and, :or, :not, :in]
      |> Enum.map(&assert is_strict_bool_comparison(&1))
    end

    test "guard is_relaxed_bool_comparison" do
      [:&&, :||, :!]
      |> Enum.map(&assert is_relaxed_bool_comparison(&1))
    end
  end

  describe "strict comparisons" do
    test "strict boolean and" do
      {:ok, ast} = Code.string_to_quoted("true and false")

      assert %{
               body: "and",
               kind: :comparison,
               left: %{body: "true", kind: :literal, type: [:Boolean]},
               right: %{body: "false", kind: :literal, type: [:Boolean]}
             } == Comparison.parse(ast, [])
    end

    test "and negate" do
      {:ok, ast} = Code.string_to_quoted("true and not false")

      assert %{
               body: "and",
               kind: :comparison,
               left: %{body: "true", kind: :literal, type: [:Boolean]},
               right: %{
                 body: "not",
                 kind: :negate,
                 expr: %{body: "false", kind: :literal, type: [:Boolean]}
               }
             } ==
               Comparison.parse(ast, [])
    end

    test "strict boolean negate" do
      {:ok, ast} = Code.string_to_quoted("not false")

      assert %{
               body: "not",
               kind: :negate,
               expr: %{body: "false", kind: :literal, type: [:Boolean]}
             } ==
               Comparison.parse(ast, [])
    end

    test "strict boolean membership insclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar in [:foo, :bar, :baz]")

      assert %{
               body: "membership",
               kind: :comparison,
               left: %{body: "foobar", kind: :literal, type: [:Variable]},
               right: [
                 %{body: "foo", kind: :literal, type: [:Atom]},
                 %{body: "bar", kind: :literal, type: [:Atom]},
                 %{body: "baz", kind: :literal, type: [:Atom]}
               ]
             } ==
               Comparison.parse(ast, [])
    end

    test "strict boolean membership exsclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar not in [:foo, :bar, :baz]")

      assert %{
               body: "not",
               kind: :negate,
               expr: %{
                 body: "membership",
                 kind: :comparison,
                 left: %{
                   type: [:Variable],
                   body: "foobar",
                   kind: :literal
                 },
                 right: [
                   %{type: [:Atom], body: "foo", kind: :literal},
                   %{type: [:Atom], body: "bar", kind: :literal},
                   %{type: [:Atom], body: "baz", kind: :literal}
                 ]
               }
             } ==
               Comparison.parse(ast, [])
    end

    test "strict boolean or" do
      {:ok, ast} = Code.string_to_quoted("false or true")

      assert %{
               body: "or",
               kind: :comparison,
               left: %{body: "false", kind: :literal, type: [:Boolean]},
               right: %{body: "true", kind: :literal, type: [:Boolean]}
             } == Comparison.parse(ast, [])
    end

    test "strictly equal to" do
      {:ok, ast} = Code.string_to_quoted("foo === :bar")

      assert %{
               body: "===",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Comparison.parse(ast, [])
    end

    test "strictly not equal to" do
      {:ok, ast} = Code.string_to_quoted("1 !== 1.0")

      assert %{
               body: "!==",
               kind: :comparison,
               left: %{body: "1", kind: :literal, type: [:Integer]},
               right: %{body: "1.0", kind: :literal, type: [:Float]}
             } == Comparison.parse(ast, [])
    end
  end

  describe "relaxed comparisons" do
    test "equal to" do
      {:ok, ast} = Code.string_to_quoted("foo == :bar")

      assert %{
               body: "==",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Comparison.parse(ast, [])
    end

    test "not equal to" do
      {:ok, ast} = Code.string_to_quoted("foo != :bar")

      assert %{
               body: "!=",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Comparison.parse(ast, [])
    end
  end

  describe "less and more comparisons" do
    test "less-than" do
      {:ok, ast} = Code.string_to_quoted("foo < 5")

      assert %{
               body: "<",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Comparison.parse(ast, [])
    end

    test "more-than" do
      {:ok, ast} = Code.string_to_quoted("foo > 5")

      assert %{
               body: ">",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Comparison.parse(ast, [])
    end

    test "less-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo <= 5")

      assert %{
               body: "<=",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Comparison.parse(ast, [])
    end

    test "greater-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo >= 5")

      assert %{
               body: ">=",
               kind: :comparison,
               left: %{body: "foo", kind: :literal, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Comparison.parse(ast, [])
    end
  end
end
