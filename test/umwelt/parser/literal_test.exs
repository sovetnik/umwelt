defmodule Umwelt.Parser.LiteralTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Literal

  test "undefined variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %{:body => "foo", kind: :Variable, type: %{kind: :Literal, type: :anything}} ==
             Literal.parse(ast)
  end

  test "read attr" do
    {:ok, ast} = Code.string_to_quoted("@foo")

    assert %{body: "foo", kind: :Value, type: %{kind: :Literal, type: :read_attr}} ==
             Literal.parse(ast)
  end

  test "atom" do
    {:ok, ast} = Code.string_to_quoted(":foo")

    assert %{body: "foo", kind: :Value, type: %{kind: :Literal, type: :atom}} ==
             Literal.parse(ast)
  end

  test "boolean true" do
    {:ok, ast} = Code.string_to_quoted("true")

    assert %{body: "true", kind: :Value, type: %{kind: :Literal, type: :boolean}} ==
             Literal.parse(ast)
  end

  test "boolean false" do
    {:ok, ast} = Code.string_to_quoted("false")

    assert %{body: "false", kind: :Value, type: %{kind: :Literal, type: :boolean}} ==
             Literal.parse(ast)
  end

  test "float" do
    {:ok, ast} = Code.string_to_quoted("13.42")

    assert %{body: "13.42", kind: :Value, type: %{kind: :Literal, type: :float}} ==
             Literal.parse(ast)
  end

  test "integer" do
    {:ok, ast} = Code.string_to_quoted("23")

    assert %{body: "23", kind: :Value, type: %{kind: :Literal, type: :integer}} ==
             Literal.parse(ast)
  end
end
