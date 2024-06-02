defmodule Umwelt.Parser.TupleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Tuple

  test "empty" do
    {:ok, ast} = Code.string_to_quoted("{}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: []
           } == Tuple.parse(ast, [])
  end

  test "tuple single" do
    {:ok, ast} = Code.string_to_quoted("{:foo}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [%{body: "foo", kind: :Value, type: %{kind: :Literal, type: :atom}}]
           } ==
             Tuple.parse(ast, [])
  end

  test "tuple pair var" do
    {:ok, ast} = Code.string_to_quoted("{:ok, result}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [
               %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
               %{body: "result", kind: :Variable, type: %{kind: :Literal, type: :anything}}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair binary" do
    {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [
               %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
               %{body: "binary", kind: :Value, type: %{kind: :Literal, type: :binary}}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair integer" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [
               %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
               %{body: "13", kind: :Value, type: %{kind: :Literal, type: :integer}}
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple pair matched" do
    {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [
               %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
               %{
                 body: "result",
                 kind: :Match,
                 term: %{
                   keyword: [],
                   kind: :Value,
                   type: %{name: :Result, path: [:Result], kind: :Alias}
                 }
               }
             ]
           } == Tuple.parse(ast, [])
  end

  test "tuple triplet" do
    {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

    assert %{
             kind: :Value,
             type: %{kind: :Structure, type: :tuple},
             elements: [
               %{body: "error", kind: :Value, type: %{kind: :Literal, type: :atom}},
               %{body: "msg", kind: :Variable, type: %{kind: :Literal, type: :anything}},
               %{body: "details", kind: :Variable, type: %{kind: :Literal, type: :anything}}
             ]
           } == Tuple.parse(ast, [])
  end
end
