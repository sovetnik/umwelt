defmodule Umwelt.Parser.ComparsionTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Comparsion

  import Umwelt.Parser.Comparsion,
    only: [
      is_comparsion: 1,
      is_strict_bool_comparsion: 1
    ]

  test "guard is_comparsion" do
    assert is_comparsion(:==)
  end

  test "guard is_strict_bool_comparsion(" do
    assert is_strict_bool_comparsion(:and)
  end

  test "and" do
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

  test "negate" do
    {:ok, ast} = Code.string_to_quoted("not false")

    assert %{
             body: "not",
             kind: :negate,
             expr: %{body: "false", kind: [:Boolean]}
           } ==
             Comparsion.parse(ast, [])
  end

  test "inclusion" do
    {:ok, ast} = Code.string_to_quoted("foobar in [:foo, :bar, :baz]")

    assert %{
             body: "inclusion",
             kind: :inclusion,
             left: %{body: "foobar", kind: [:Capture]},
             right: [
               %{body: "foo", kind: [:Atom]},
               %{body: "bar", kind: [:Atom]},
               %{body: "baz", kind: [:Atom]}
             ]
           } ==
             Comparsion.parse(ast, [])
  end

  test "or" do
    {:ok, ast} = Code.string_to_quoted("false or true")

    assert %{
             body: "or",
             kind: :comparsion,
             left: %{body: "false", kind: [:Boolean]},
             right: %{body: "true", kind: [:Boolean]}
           } == Comparsion.parse(ast, [])
  end

  test "equal" do
    {:ok, ast} = Code.string_to_quoted("foo == :bar")

    assert %{
             body: "==",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "not equal" do
    {:ok, ast} = Code.string_to_quoted("foo != :bar")

    assert %{
             body: "!=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "strict equal" do
    {:ok, ast} = Code.string_to_quoted("foo === :bar")

    assert %{
             body: "===",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "strict not equal" do
    {:ok, ast} = Code.string_to_quoted("foo !== :bar")

    assert %{
             body: "!==",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "bar", kind: [:Atom]}
           } == Comparsion.parse(ast, [])
  end

  test "less" do
    {:ok, ast} = Code.string_to_quoted("foo < 5")

    assert %{
             body: "<",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "more" do
    {:ok, ast} = Code.string_to_quoted("foo > 5")

    assert %{
             body: ">",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "less equal" do
    {:ok, ast} = Code.string_to_quoted("foo <= 5")

    assert %{
             body: "<=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end

  test "more equal" do
    {:ok, ast} = Code.string_to_quoted("foo >= 5")

    assert %{
             body: ">=",
             kind: :comparsion,
             left: %{body: "foo", kind: [:Capture]},
             right: %{body: "5", kind: [:Integer]}
           } == Comparsion.parse(ast, [])
  end
end
