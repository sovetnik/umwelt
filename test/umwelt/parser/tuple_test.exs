defmodule Umwelt.Parser.TupleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Tuple

  test "empty" do
    {:ok, ast} = Code.string_to_quoted("{}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: []
           } == Tuple.parse(ast, [])
  end

  test "tuple single" do
    {:ok, ast} = Code.string_to_quoted("{:foo}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [%{body: "foo", kind: :literal, type: [:Atom]}]
           } ==
             Tuple.parse(ast, [])
  end

  test "tuple pair var" do
    {:ok, ast} = Code.string_to_quoted("{:ok, result}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "result", kind: :literal, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair binary" do
    {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "binary", kind: :literal, type: [:Binary]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair integer" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "13", kind: :literal, type: [:Integer]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair matched" do
    {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{
                 body: "result",
                 kind: :match,
                 term: %{context: [:Result], body: :map, kind: :structure, keyword: []}
               }
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple triplet" do
    {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

    assert %{
             body: :tuple,
             kind: :structure,
             elements: [
               %{body: "error", kind: :literal, type: [:Atom]},
               %{body: "msg", kind: :literal, type: [:Variable]},
               %{body: "details", kind: :literal, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end
end
