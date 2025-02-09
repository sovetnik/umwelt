defmodule Umwelt.Parser.OperatorTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Literal,
    Operator,
    Structure,
    Unary,
    Value,
    Variable
  }

  alias Umwelt.Parser

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
    test "guard is_special_operator" do
      [:^, :., :=, :&, :"::"]
      |> Enum.map(&assert is_special_operator(&1))
    end

    test "guard is_comparison_operator" do
      [:==, :!=, :===, :!==, :<, :<=, :>, :>=]
      |> Enum.map(&assert is_comparison_operator(&1))
    end

    test "guard is_other_operator" do
      [:\\, :in, :when]
      |> Enum.map(&assert is_other_operator(&1))
    end

    test "guard is_relaxed_bool_operator" do
      [:&&, :||, :!]
      |> Enum.map(&assert is_relaxed_bool_operator(&1))
    end

    test "guard is_strict_bool_operator" do
      [:and, :or, :not]
      |> Enum.map(&assert is_strict_bool_operator(&1))
    end

    test "guard is_unary" do
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

      assert %Operator{
               name: "membership",
               left: %Variable{
                 body: "foobar",
                 type: %Literal{type: :anything}
               },
               right: [
                 %Value{body: "foo", type: %Literal{type: :atom}},
                 %Value{body: "bar", type: %Literal{type: :atom}},
                 %Value{body: "baz", type: %Literal{type: :atom}}
               ]
             } == Parser.Operator.parse(ast, [], [])
    end

    test "membership exsclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar not in [:foo, :bar, :baz]")

      assert %Unary{
               name: "not",
               expr: %Operator{
                 name: "membership",
                 left: %Variable{
                   type: %Literal{type: :anything},
                   body: "foobar"
                 },
                 right: [
                   %Value{body: "foo", type: %Literal{type: :atom}},
                   %Value{body: "bar", type: %Literal{type: :atom}},
                   %Value{body: "baz", type: %Literal{type: :atom}}
                 ]
               }
             } == Parser.Operator.parse(ast, [], [])
    end
  end

  describe "matching" do
    test "right match tuple" do
      {:ok, ast} = Code.string_to_quoted("{:ok, foo} = bar")

      assert %Operator{
               name: "match",
               left: %Structure{
                 type: %Literal{type: :tuple},
                 elements: [
                   %Value{type: %Literal{type: :atom}, body: "ok"},
                   %Variable{type: %Literal{type: :anything}, body: "foo"}
                 ]
               },
               right: %Umwelt.Felixir.Variable{
                 body: "bar",
                 type: %Umwelt.Felixir.Literal{type: :anything}
               }
             } == Parser.Operator.parse(ast, [], [])
    end

    test "match typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %Operator{
               name: "match",
               left: %Structure{
                 type: %Alias{name: "Bar", path: ["Bar"]},
                 elements: []
               },
               right: %Umwelt.Felixir.Variable{
                 body: "bar",
                 type: %Umwelt.Felixir.Literal{type: :anything}
               }
             } == Parser.Operator.parse(ast, [], [])
    end

    test "match list with atom" do
      {:ok, ast} = Code.string_to_quoted(":foo = bar")

      assert %Operator{
               name: "match",
               left: %Umwelt.Felixir.Value{
                 body: "foo",
                 type: %Umwelt.Felixir.Literal{type: :atom}
               },
               right: %Umwelt.Felixir.Variable{
                 body: "bar",
                 type: %Umwelt.Felixir.Literal{type: :anything}
               }
             } == Parser.Operator.parse(ast, [], [])
    end

    test "match list with atom in list" do
      {:ok, ast} = Code.string_to_quoted("[:foo] = bar")

      assert %Operator{
               left: %Umwelt.Felixir.Structure{
                 type: %Umwelt.Felixir.Literal{type: :list},
                 elements: [
                   %Umwelt.Felixir.Value{body: "foo", type: %Umwelt.Felixir.Literal{type: :atom}}
                 ]
               },
               name: "match",
               right: %Umwelt.Felixir.Variable{
                 body: "bar",
                 type: %Umwelt.Felixir.Literal{type: :anything}
               }
             } == Parser.Operator.parse(ast, [], [])
    end
  end

  describe "strict operators" do
    test "strict boolean and" do
      {:ok, ast} = Code.string_to_quoted("true and false")

      assert %Operator{
               name: "and",
               left: %Value{body: "true", type: %Literal{type: :boolean}},
               right: %Value{body: "false", type: %Literal{type: :boolean}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "and negate" do
      {:ok, ast} = Code.string_to_quoted("true and not false")

      assert %Operator{
               name: "and",
               left: %Value{body: "true", type: %Literal{type: :boolean}},
               right: %Unary{
                 name: "not",
                 expr: %Value{body: "false", type: %Literal{type: :boolean}}
               }
             } == Parser.Operator.parse(ast, [], [])
    end

    test "strict boolean negate" do
      {:ok, ast} = Code.string_to_quoted("not false")

      assert %Unary{
               name: "not",
               expr: %Value{body: "false", type: %Literal{type: :boolean}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "strict boolean or" do
      {:ok, ast} = Code.string_to_quoted("false or true")

      assert %Operator{
               name: "or",
               left: %Value{body: "false", type: %Literal{type: :boolean}},
               right: %Value{body: "true", type: %Literal{type: :boolean}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "strictly equal to" do
      {:ok, ast} = Code.string_to_quoted("foo === :bar")

      assert %Operator{
               name: "===",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "bar", type: %Literal{type: :atom}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "strictly not equal to" do
      {:ok, ast} = Code.string_to_quoted("1 !== 1.0")

      assert %Operator{
               name: "!==",
               left: %Value{body: "1", type: %Literal{type: :integer}},
               right: %Value{body: "1.0", type: %Literal{type: :float}}
             } == Parser.Operator.parse(ast, [], [])
    end
  end

  describe "relaxed operators" do
    test "equal to" do
      {:ok, ast} = Code.string_to_quoted("foo == :bar")

      assert %Operator{
               name: "==",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "bar", type: %Literal{type: :atom}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "not equal to" do
      {:ok, ast} = Code.string_to_quoted("foo != :bar")

      assert %Operator{
               name: "!=",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "bar", type: %Literal{type: :atom}}
             } == Parser.Operator.parse(ast, [], [])
    end
  end

  describe "less and more operators" do
    test "less-than" do
      {:ok, ast} = Code.string_to_quoted("foo < 5")

      assert %Operator{
               name: "<",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "5", type: %Literal{type: :integer}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "more-than" do
      {:ok, ast} = Code.string_to_quoted("foo > 5")

      assert %Operator{
               name: ">",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "5", type: %Literal{type: :integer}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "less-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo <= 5")

      assert %Operator{
               name: "<=",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "5", type: %Literal{type: :integer}}
             } == Parser.Operator.parse(ast, [], [])
    end

    test "greater-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo >= 5")

      assert %Operator{
               name: ">=",
               left: %Variable{body: "foo", type: %Literal{type: :anything}},
               right: %Value{body: "5", type: %Literal{type: :integer}}
             } == Parser.Operator.parse(ast, [], [])
    end
  end
end
