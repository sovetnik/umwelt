defmodule Umwelt.Parser.MatchTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Match

  test "typed variable Bar" do
    {:ok, ast} = Code.string_to_quoted("%Bar{} = bar")

    assert %{:body => "bar", :match => [:Bar]} == Match.parse(ast, [])
  end

  test "list with atom" do
    {:ok, ast} = Code.string_to_quoted(":foo = bar")

    assert %{body: "bar", match: %{body: "foo", kind: [:Atom]}} == Match.parse(ast, [])
  end

  test "list with atom in list" do
    {:ok, ast} = Code.string_to_quoted("[:foo] = bar")

    assert %{body: "bar", match: [%{body: "foo", kind: [:Atom]}]} == Match.parse(ast, [])
  end
end
