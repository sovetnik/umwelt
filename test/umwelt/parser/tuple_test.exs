defmodule Umwelt.Parser.TupleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Tuple

  test "empty" do
    {:ok, ast} = Code.string_to_quoted("{}")

    assert %{tuple: []} == Tuple.parse(ast, [])
  end

  test "tuple single" do
    {:ok, ast} = Code.string_to_quoted("{:foo}")

    assert %{tuple: [%{body: "foo", kind: :literal, type: [:Atom]}]} ==
             Tuple.parse(ast, [])
  end

  test "tuple pair var" do
    {:ok, ast} = Code.string_to_quoted("{:ok, result}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "result", kind: :literal, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair binary" do
    {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "binary", kind: :literal, type: [:Binary]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair integer" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "13", kind: :literal, type: [:Integer]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair matched" do
    {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "result", kind: :match, term: [:Result]}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple triplet" do
    {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

    assert %{
             tuple: [
               %{body: "error", kind: :literal, type: [:Atom]},
               %{body: "msg", kind: :literal, type: [:Variable]},
               %{body: "details", kind: :literal, type: [:Variable]}
             ]
           } == Tuple.parse(ast, [])
  end
end
