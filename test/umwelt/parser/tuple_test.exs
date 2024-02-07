defmodule Umwelt.Parser.TupleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Tuple

  test "empty" do
    {:ok, ast} = Code.string_to_quoted("{}")

    assert %{
             type: [:Tuple],
             elements: []
           } == Tuple.parse(ast, [])
  end

  test "tuple single" do
    {:ok, ast} = Code.string_to_quoted("{:foo}")

    assert %{
             type: [:Tuple],
             elements: [%{body: "foo", kind: :value, type: [:Atom]}]
           } ==
             Tuple.parse(ast, [])
  end

  test "tuple pair var" do
    {:ok, ast} = Code.string_to_quoted("{:ok, result}")

    assert %{
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :value, type: [:Atom]},
               %{body: "result", kind: :variable, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair binary" do
    {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

    assert %{
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :value, type: [:Atom]},
               %{body: "binary", kind: :value, type: [:Binary]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair integer" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :value, type: [:Atom]},
               %{body: "13", kind: :value, type: [:Integer]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair matched" do
    {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

    assert %{
             type: [:Tuple],
             elements: [
               %{body: "ok", kind: :value, type: [:Atom]},
               %{
                 body: "result",
                 kind: :match,
                 term: %{context: [:Result], type: [:Map], keyword: []}
               }
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple triplet" do
    {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

    assert %{
             type: [:Tuple],
             elements: [
               %{body: "error", kind: :value, type: [:Atom]},
               %{body: "msg", kind: :variable, type: [:Variable]},
               %{body: "details", kind: :variable, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end
end
