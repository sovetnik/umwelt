defmodule Umwelt.Parser.OperatorTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Operator

  import Umwelt.Parser.Operator, only: [is_operator: 1]

  test "guard is_operator" do
    [:^, :., :=, :&, :"::", :\\]
    |> Enum.map(&assert is_operator(&1))
  end

  test "match typed variable Bar" do
    {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

    assert %{
             body: "bar",
             kind: :match,
             term: %{
               context: [:Bar],
               body: :map,
               kind: :structure,
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
