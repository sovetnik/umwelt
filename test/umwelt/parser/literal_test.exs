defmodule Umwelt.Parser.LiteralTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Literal

  test "undefined variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %{:body => "foo", :kind => [:Variable]} == Literal.parse(ast)
  end

  test "atom" do
    {:ok, ast} = Code.string_to_quoted(":foo")

    assert %{body: "foo", kind: [:Atom]} == Literal.parse(ast)
  end

  test "boolean true" do
    {:ok, ast} = Code.string_to_quoted("true")

    assert %{body: "true", kind: [:Boolean]} == Literal.parse(ast)
  end

  test "boolean false" do
    {:ok, ast} = Code.string_to_quoted("false")

    assert %{body: "false", kind: [:Boolean]} == Literal.parse(ast)
  end

  test "float" do
    {:ok, ast} = Code.string_to_quoted("13.42")

    assert %{body: "13.42", kind: [:Float]} == Literal.parse(ast)
  end

  test "integer" do
    {:ok, ast} = Code.string_to_quoted("23")

    assert %{body: "23", kind: [:Integer]} == Literal.parse(ast)
  end
end
