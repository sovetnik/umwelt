defmodule Umwelt.Parser.TupleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Tuple

  test "empty" do
    {:ok, ast} = Code.string_to_quoted("{}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: []
           } == Tuple.parse(ast, [])
  end

  test "tuple single" do
    {:ok, ast} = Code.string_to_quoted("{:foo}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [%{body: "foo", kind: :Value, type: [:Atom]}]
           } ==
             Tuple.parse(ast, [])
  end

  test "tuple pair var" do
    {:ok, ast} = Code.string_to_quoted("{:ok, result}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :Value, type: [:Atom]},
               %{body: "result", kind: :Variable, type: [:Anything]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair binary" do
    {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :Value, type: [:Atom]},
               %{body: "binary", kind: :Value, type: [:Binary]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair integer" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :Value, type: [:Atom]},
               %{body: "13", kind: :Value, type: [:Integer]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair matched" do
    {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :Value, type: [:Atom]},
               %{
                 body: "result",
                 kind: :Match,
                 term: %{kind: :Value, type: [:Result], keyword: []}
               }
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple triplet" do
    {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

    assert %{
             kind: :Value,
             type: [:Tuple],
             elements: [
               %{body: "error", kind: :Value, type: [:Atom]},
               %{body: "msg", kind: :Variable, type: [:Anything]},
               %{body: "details", kind: :Variable, type: [:Anything]}
             ]
           } == Tuple.parse(ast, [])
  end
end
