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
               kind: :operator,
               left: %{body: "foobar", kind: :variable, type: [:Variable]},
               right: [
                 %{body: "foo", kind: :literal, type: [:Atom]},
                 %{body: "bar", kind: :literal, type: [:Atom]},
                 %{body: "baz", kind: :literal, type: [:Atom]}
               ]
             } == Operator.parse(ast, [])
    end

    test "membership exsclusion" do
      {:ok, ast} = Code.string_to_quoted("foobar not in [:foo, :bar, :baz]")

      assert %{
               body: "not",
               kind: :operator,
               expr: %{
                 body: "membership",
                 kind: :operator,
                 left: %{
                   type: [:Variable],
                   body: "foobar",
                   kind: :variable
                 },
                 right: [
                   %{type: [:Atom], body: "foo", kind: :literal},
                   %{type: [:Atom], body: "bar", kind: :literal},
                   %{type: [:Atom], body: "baz", kind: :literal}
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
               kind: :match,
               term: %{
                 type: [:Tuple],
                 elements: [
                   %{type: [:Atom], body: "ok", kind: :literal},
                   %{type: [:Variable], body: "foo", kind: :variable}
                 ]
               }
             } == Operator.parse(ast, [])
    end

    test "match typed variable Bar" do
      {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: %{
                 context: [:Bar],
                 type: [:Map],
                 keyword: []
               }
             } == Operator.parse(ast, [])
    end

    test "match list with atom" do
      {:ok, ast} = Code.string_to_quoted(":foo = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: %{type: [:Atom], body: "foo", kind: :literal}
             } == Operator.parse(ast, [])
    end

    test "match list with atom in list" do
      {:ok, ast} = Code.string_to_quoted("[:foo] = bar")

      assert %{
               body: "bar",
               kind: :match,
               term: [%{type: [:Atom], body: "foo", kind: :literal}]
             } == Operator.parse(ast, [])
    end
  end

  describe "strict operators" do
    test "strict boolean and" do
      {:ok, ast} = Code.string_to_quoted("true and false")

      assert %{
               body: "and",
               kind: :operator,
               left: %{body: "true", kind: :literal, type: [:Boolean]},
               right: %{body: "false", kind: :literal, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "and negate" do
      {:ok, ast} = Code.string_to_quoted("true and not false")

      assert %{
               body: "and",
               kind: :operator,
               left: %{body: "true", kind: :literal, type: [:Boolean]},
               right: %{
                 body: "not",
                 kind: :operator,
                 expr: %{body: "false", kind: :literal, type: [:Boolean]}
               }
             } == Operator.parse(ast, [])
    end

    test "strict boolean negate" do
      {:ok, ast} = Code.string_to_quoted("not false")

      assert %{
               body: "not",
               kind: :operator,
               expr: %{body: "false", kind: :literal, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "strict boolean or" do
      {:ok, ast} = Code.string_to_quoted("false or true")

      assert %{
               body: "or",
               kind: :operator,
               left: %{body: "false", kind: :literal, type: [:Boolean]},
               right: %{body: "true", kind: :literal, type: [:Boolean]}
             } == Operator.parse(ast, [])
    end

    test "strictly equal to" do
      {:ok, ast} = Code.string_to_quoted("foo === :bar")

      assert %{
               body: "===",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Operator.parse(ast, [])
    end

    test "strictly not equal to" do
      {:ok, ast} = Code.string_to_quoted("1 !== 1.0")

      assert %{
               body: "!==",
               kind: :operator,
               left: %{body: "1", kind: :literal, type: [:Integer]},
               right: %{body: "1.0", kind: :literal, type: [:Float]}
             } == Operator.parse(ast, [])
    end
  end

  describe "relaxed operators" do
    test "equal to" do
      {:ok, ast} = Code.string_to_quoted("foo == :bar")

      assert %{
               body: "==",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Operator.parse(ast, [])
    end

    test "not equal to" do
      {:ok, ast} = Code.string_to_quoted("foo != :bar")

      assert %{
               body: "!=",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "bar", kind: :literal, type: [:Atom]}
             } == Operator.parse(ast, [])
    end
  end

  describe "less and more operators" do
    test "less-than" do
      {:ok, ast} = Code.string_to_quoted("foo < 5")

      assert %{
               body: "<",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "more-than" do
      {:ok, ast} = Code.string_to_quoted("foo > 5")

      assert %{
               body: ">",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "less-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo <= 5")

      assert %{
               body: "<=",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Operator.parse(ast, [])
    end

    test "greater-than or equal to" do
      {:ok, ast} = Code.string_to_quoted("foo >= 5")

      assert %{
               body: ">=",
               kind: :operator,
               left: %{body: "foo", kind: :variable, type: [:Variable]},
               right: %{body: "5", kind: :literal, type: [:Integer]}
             } == Operator.parse(ast, [])
    end
  end
end
