defmodule Umwelt.Parser.OperatorTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Operator

  import Umwelt.Parser.Operator,
    only: [
      is_special_operator: 1,
      is_comparison_operator: 1,
      is_other_operator: 1,
      is_relaxed_bool_operator: 1,
      is_strict_bool_operator: 1,
      is_unary: 1,
      is_operator: 1
    ]

  describe "guards" do
    test "guard is_special_operator(" do
      [:^, :., :=, :&, :"::"]
      |> Enum.map(&assert is_special_operator(&1))
    end

    test "guard is_comparison_operator(" do
      [:==, :!=, :===, :!==, :<, :<=, :>, :>=]
      |> Enum.map(&assert is_comparison_operator(&1))
    end

    test "guard is_other_operator(" do
      [:\\, :in, :when]
      |> Enum.map(&assert is_other_operator(&1))
    end

    test "guard is_relaxed_bool_operator(" do
      [:&&, :||, :!]
      |> Enum.map(&assert is_relaxed_bool_operator(&1))
    end

    test "guard is_strict_bool_operator(" do
      [:and, :or, :not]
      |> Enum.map(&assert is_strict_bool_operator(&1))
    end

    test "guard is_unary(" do
      [:!, :^, :not, :&]
      |> Enum.map(&assert is_unary(&1))
    end

    test "guard is_operator" do
      [:^, :., :=, :&, :"::", :\\, :in, :!, :not, :when]
      |> Enum.map(&assert is_operator(&1))
    end
  end

  describe "membership" do
    test "membership insclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar in [:foo, :bar, :baz]")

      assert %{
               body: "membership",
               kind: :Operator,
               left: %{body: "foobar", kind: :Variable, type: [:Anything]},
               right: [
                 %{body: "foo", kind: :Value, type: [:Atom]},
                 %{body: "bar", kind: :Value, type: [:Atom]},
                 %{body: "baz", kind: :Value, type: [:Atom]}
               ]
             } == Operator.parse(ast, [])
    end

    test "membership exsclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar not in [:foo, :bar, :baz]")

      assert %{
               body: "not",
               kind: :Operator,
               expr: %{
                 body: "membership",
                 kind: :Operator,
                 left: %{
                   type: [:Anything],
                   body: "foobar",
                   kind: :Variable
                 },
                 right: [
                   %{type: [:Atom], body: "foo", kind: :Value},
                   %{type: [:Atom], body: "bar", kind: :Value},
                   %{type: [:Atom], body: "baz", kind: :Value}
                 ]
               }
             } == Operator.parse(ast, [])
    end
  end

  describe "matching" do
    test "right match tuple" do
      {:ok, ast} = Code.string_to_quoted("{:ok, foo} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 kind: :Value,
                 type: [:Tuple],
                 elements: [
                   %{type: [:Atom], body: "ok", kind: :Value},
                   %{type: [:Anything], body: "foo", kind: :Variable}
                 ]
               }
             } == Operator.parse(ast, [])
    end

    test "match typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{
                 kind: :Value,
                 type: %{name: :Bar, path: [:Bar], kind: :Alias},
                 keyword: []
               }
             } == Operator.parse(ast, [])
    end

    test "match list with atom" do
      {:ok, ast} = Code.string_to_quoted(":foo = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: %{type: [:Atom], body: "foo", kind: :Value}
             } == Operator.parse(ast, [])
    end

    test "match list with atom in list" do
      {:ok, ast} = Code.string_to_quoted("[:foo] = bar")

      assert %{
               body: "bar",
               kind: :Match,
               term: [%{type: [:Atom], body: "foo", kind: :Value}]
             } == Operator.parse(ast, [])
    end
  end

  describe "strict operators" do
    test "strict boolean and" do
      {:ok, ast} = Code.string_to_quoted("true and false")

      assert %{
               body: "and",
               kind: :Operator,
               left: %{body: "true", kind: :Value, type: [:Boolean]},
               right: %{body: "false", kind: :Value, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "and negate" do
      {:ok, ast} = Code.string_to_quoted("true and not false")

      assert %{
               body: "and",
               kind: :Operator,
               left: %{body: "true", kind: :Value, type: [:Boolean]},
               right: %{
                 body: "not",
                 kind: :Operator,
                 expr: %{body: "false", kind: :Value, type: [:Boolean]}
               }
             } == Operator.parse(ast, [])
    end

    test "strict boolean negate" do
      {:ok, ast} = Code.string_to_quoted("not false")

      assert %{
               body: "not",
               kind: :Operator,
               expr: %{body: "false", kind: :Value, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "strict boolean or" do
      {:ok, ast} = Code.string_to_quoted("false or true")

      assert %{
               body: "or",
               kind: :Operator,
               left: %{body: "false", kind: :Value, type: [:Boolean]},
               right: %{body: "true", kind: :Value, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "strictly equal to" do
      {:ok, ast} = Code.string_to_quoted("foo === :bar")

      assert %{
               body: "===",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "bar", kind: :Value, type: [:Atom]}
             } == Operator.parse(ast, [])
    end

    test "strictly not equal to" do
      {:ok, ast} = Code.string_to_quoted("1 !== 1.0")

      assert %{
               body: "!==",
               kind: :Operator,
               left: %{body: "1", kind: :Value, type: [:Integer]},
               right: %{body: "1.0", kind: :Value, type: [:Float]}
             } == Operator.parse(ast, [])
    end
  end

  describe "relaxed operators" do
    test "equal to" do
      {:ok, ast} = Code.string_to_quoted("foo == :bar")

      assert %{
               body: "==",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "bar", kind: :Value, type: [:Atom]}
             } == Operator.parse(ast, [])
    end

    test "not equal to" do
      {:ok, ast} = Code.string_to_quoted("foo != :bar")

      assert %{
               body: "!=",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "bar", kind: :Value, type: [:Atom]}
             } == Operator.parse(ast, [])
    end
  end

  describe "less and more operators" do
    test "less-than" do
      {:ok, ast} = Code.string_to_quoted("foo < 5")

      assert %{
               body: "<",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "5", kind: :Value, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "more-than" do
      {:ok, ast} = Code.string_to_quoted("foo > 5")

      assert %{
               body: ">",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "5", kind: :Value, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "less-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo <= 5")

      assert %{
               body: "<=",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "5", kind: :Value, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "greater-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo >= 5")

      assert %{
               body: ">=",
               kind: :Operator,
               left: %{body: "foo", kind: :Variable, type: [:Anything]},
               right: %{body: "5", kind: :Value, type: [:Integer]}
             } == Operator.parse(ast, [])
    end
  end
end
