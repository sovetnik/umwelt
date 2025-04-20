defmodule Umwelt.Parser.LiteralTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{Literal, Value, Variable}
  alias Umwelt.Parser

  import Umwelt.Parser.Literal,
    only: [
      is_literal_term: 1,
      is_literal_structure: 1,
      is_literal: 1
    ]

  describe "literal guards" do
    test "guard is_literal_term" do
      ~w|atom boolean binary float integer read_attr string|a
      |> Enum.map(&assert is_literal_term(&1))
    end

    test "guard is_literal_structure" do
      ~w|bitstring list map tuple|a
      |> Enum.map(&assert is_literal_structure(&1))
    end

    test "guard is_literal" do
      ~w|atom float map tuple|a
      |> Enum.map(&assert is_literal(&1))
    end

    test "guard fails" do
      ~w|foo bar baz|a
      |> Enum.map(&refute is_literal(&1))
    end
  end

  test "undefined variable" do
    {:ok, ast} = Code.string_to_quoted("foo")

    assert %Variable{:body => "foo", type: %Literal{type: :anything}} ==
             Parser.Literal.parse(ast)
  end

  test "read attr" do
    {:ok, ast} = Code.string_to_quoted("@foo")

    assert %Value{body: "foo", type: %Literal{type: :read_attr}} ==
             Parser.Literal.parse(ast)
  end

  test "atom" do
    {:ok, ast} = Code.string_to_quoted(":foo")

    assert %Value{body: "foo", type: %Literal{type: :atom}} ==
             Parser.Literal.parse(ast)
  end

  test "binary" do
    assert %Value{body: "\xFF\xFF", type: %Literal{type: :binary}} ==
             Parser.Literal.parse(<<0xFFFF::16>>)
  end

  test "string symbol" do
    assert %Value{body: "﷐", type: %Literal{type: :string}} ==
             Parser.Literal.parse(<<0xEF, 0xB7, 0x90>>)
  end

  test "string" do
    assert %Value{body: "foo", type: %Literal{type: :string}} ==
             Parser.Literal.parse("foo")
  end

  test "boolean true" do
    {:ok, ast} = Code.string_to_quoted("true")

    assert %Value{body: "true", type: %Literal{type: :boolean}} ==
             Parser.Literal.parse(ast)
  end

  test "boolean false" do
    {:ok, ast} = Code.string_to_quoted("false")

    assert %Value{body: "false", type: %Literal{type: :boolean}} ==
             Parser.Literal.parse(ast)
  end

  test "float" do
    {:ok, ast} = Code.string_to_quoted("13.42")

    assert %Value{body: "13.42", type: %Literal{type: :float}} ==
             Parser.Literal.parse(ast)
  end

  test "integer" do
    {:ok, ast} = Code.string_to_quoted("23")

    assert %Value{body: "23", type: %Literal{type: :integer}} ==
             Parser.Literal.parse(ast)
  end
end
