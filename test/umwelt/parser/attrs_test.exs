defmodule Umwelt.Parser.AttrsTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{Attribute, Call, Literal, Structure, Value, Variable}
  alias Umwelt.Parser.Attrs

  test "parse module doc" do
    {:ok, ast} =
      """
        @moduledoc "Calculator"
      """
      |> Code.string_to_quoted()

    assert %{moduledoc: ["Calculator"]} == Attrs.parse(ast, [])
  end

  test "parse function doc" do
    {:ok, ast} =
      """
      @doc "summarize two nums"
      """
      |> Code.string_to_quoted()

    assert %{doc: ["summarize two nums"]} == Attrs.parse(ast, [])
  end

  test "parse function spec" do
    {:ok, ast} =
      """
      @spec foobar(fizz :: atom, buzz :: any) :: boolean
      """
      |> Code.string_to_quoted()

    assert %{
             spec: %Call{
               name: "foobar",
               type: %Literal{type: :boolean},
               arguments: [
                 %Variable{type: %Literal{type: :atom}, body: "fizz"},
                 %Variable{type: %Literal{type: :anything}, body: "buzz"}
               ]
             }
           } == Attrs.parse(ast, [], [])
  end

  test "parse attr with list" do
    {:ok, ast} =
      """
      @attribute [ :foo, :bar ]
      """
      |> Code.string_to_quoted()

    assert %Attribute{
             name: "attribute",
             value: %Structure{
               type: %Literal{type: :list},
               elements: [
                 %Value{type: %Literal{type: :atom}, body: "foo"},
                 %Value{type: %Literal{type: :atom}, body: "bar"}
               ]
             }
           } == Attrs.parse(ast, [])
  end

  test "parse attr with nil" do
    {:ok, ast} =
      """
      @options_schema nil
      """
      |> Code.string_to_quoted()

    assert %Attribute{
             name: "options_schema",
             value: %Value{type: %Literal{type: :atom}, body: "nil"}
           } == Attrs.parse(ast, [])
  end

  test "parse attr with struct" do
    {:ok, ast} =
      """
      @attribute %{foo: :bar}
      """
      |> Code.string_to_quoted()

    assert %Attribute{
             name: "attribute",
             value: %Structure{
               elements: [
                 %Structure{
                   type: %Literal{type: :tuple},
                   elements: [
                     %Value{type: %Literal{type: :atom}, body: "foo"},
                     %Value{type: %Literal{type: :atom}, body: "bar"}
                   ]
                 }
               ],
               type: %Literal{type: :map}
             }
           } == Attrs.parse(ast, [])
  end

  describe "skipped" do
    test "behaviour" do
      {:ok, ast} =
        "@behaviour Foo.Bar"
        |> Code.string_to_quoted()

      assert nil == Attrs.parse(ast, [])
    end

    test "opacue" do
      {:ok, ast} =
        "@opaque type_name :: type"
        |> Code.string_to_quoted()

      assert nil == Attrs.parse(ast, [])
    end

    test "typep" do
      {:ok, ast} =
        "@typep type_name :: type"
        |> Code.string_to_quoted()

      assert nil == Attrs.parse(ast, [])
    end
  end
end
