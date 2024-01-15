defmodule Umwelt.Parser.ComparsionTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Comparsion

  import Umwelt.Parser.Comparsion,
    only: [
      is_comparsion: 1,
      is_comparsion_operator: 1,
      is_relaxed_bool_comparsion: 1,
      is_strict_bool_comparsion: 1
    ]

  test "guard is_comparsion" do
    [:==, :&&, :and, :not, :in]
    |> Enum.map(&assert is_comparsion(&1))
  end

  test "guard is_comparsion_operator" do
    [:==, :!=, :===, :!==, :<, :<=, :>, :>=]
    |> Enum.map(&assert is_comparsion_operator(&1))
  end

  test "guard is_strict_bool_comparsion(" do
    [:and, :or, :not, :in]
    |> Enum.map(&assert is_strict_bool_comparsion(&1))
  end

  test "guard is_relaxed_bool_comparsion(" do
    [:&&, :||, :!]
    |> Enum.map(&assert is_relaxed_bool_comparsion(&1))
  end

  test "strict boolean and" do
    {:ok, ast} = Code.string_to_quoted("true and false")

    assert %{
             body: "and",
             kind: :comparsion,
             left: %{body: "true", kind: [:Boolean]},
             right: %{body: "false", kind: [:Boolean]}
           } == Comparsion.parse(ast, [])
  end

  test "and negate" do
    {:ok, ast} = Code.string_to_quoted("true and not false")

    assert %{
             body: "and",
             kind: :comparsion,
             left: %{body: "true", kind: [:Boolean]},
             right: %{
               body: "not",
               kind: :negate,
               expr: %{body: "false", kind: [:Boolean]}
             }
           } ==
             Comparsion.parse(ast, [])
  end

  test "strict boolean negate" do
    {:ok, ast} = Code.string_to_quoted("not false")

    assert %{
             body: "not",
             kind: :negate,
             expr: %{body: "false", kind: [:Boolean]}
           } ==
             Comparsion.parse(ast, [])
  end

  test "strict boolean inclusion" do
    {:ok, ast} = Code.string_to_quoted("foobar in [:foo, :bar, :baz]")

    assert %{
             body: "inclusion",
             kind: :inclusion,
             left: %{body: "foobar", kind: [:Variable]},
             right: [
               %{body: "foo", kind: [:Atom]},
               %{body: "bar", kind: [:Atom]},
               %{body: "baz", kind: [:Atom]}
             ]
           } ==
             Comparsion.parse(ast, [])
  end

  test "strict boolean or" do
    {:ok, ast} = Code.string_to_quoted("false or true")

    assert %{
             body: "or",
             kind: :comparsion,
             left: %{body: "false", kind: [:Boolean]},
             right: %{body: "true", kind: [:Boolean]}
           } == Comparsion.parse(ast, [])
  end

  test "equal to" do
    {:ok, ast} = Code.string_to_quoted("foo == :bar")

    assert %{
             body: "==",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "not equal to" do
    {:ok, ast} = Code.string_to_quoted("foo != :bar")

    assert %{
             body: "!=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "strictly equal to" do
    {:ok, ast} = Code.string_to_quoted("foo === :bar")

    assert %{
             body: "===",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "strictly not equal to" do
    {:ok, ast} = Code.string_to_quoted("1 !== 1.0")

    assert %{
             body: "!==",
             kind: :comparsion,
             left: %{body: "1", kind: [:Integer]},
             right: %{body: "1.0", kind: [:Float]}
           } == Comparsion.parse(ast, [])
  end

  test "less-than" do
    {:ok, ast} = Code.string_to_quoted("foo < 5")

    assert %{
             body: "<",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "more-than" do
    {:ok, ast} = Code.string_to_quoted("foo > 5")

    assert %{
             body: ">",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "less-than or equal to" do
    {:ok, ast} = Code.string_to_quoted("foo <= 5")

    assert %{
             body: "<=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "greater-than or equal to" do
    {:ok, ast} = Code.string_to_quoted("foo >= 5")

    assert %{
             body: ">=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Variable]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end
end
