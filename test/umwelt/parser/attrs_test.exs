defmodule Umwelt.Parser.AttrsTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Attrs

  test "parse module doc" do
    {:ok, ast} =
      """
        @moduledoc "Calculator"
      """
      |> Code.string_to_quoted()

    assert %{moduledoc: ["Calculator"]} ==
             Attrs.parse(ast)
  end

  test "parse function doc" do
    {:ok, ast} =
      """
      @doc "summarize two nums"
      """
      |> Code.string_to_quoted()

    assert %{doc: ["summarize two nums"]} ==
             Attrs.parse(ast)
  end

  test "parse function spec" do
    {:ok, ast} =
      """
      @spec foobar(fizz :: atom, buzz :: any) :: boolean
      """
      |> Code.string_to_quoted()

    assert %{
             spec: %{
               body: "foobar",
               kind: :Call,
               type: %{kind: :Literal, type: :boolean},
               arguments: [
                 %{type: %{kind: :Literal, type: :atom}, body: "fizz", kind: :Variable},
                 %{type: %{kind: :Literal, type: :anything}, body: "buzz", kind: :Variable}
               ]
             }
           } == Attrs.parse(ast)
  end

  test "parse attr with list" do
    {:ok, ast} =
      """
      @attribute [ :foo, :bar ]
      """
      |> Code.string_to_quoted()

    assert %{
             body: "attribute",
             kind: :Attr,
             value: %{
               type: %{kind: :Structure, type: :list},
               values: [
                 %{type: %{kind: :Literal, type: :atom}, body: "foo", kind: :Value},
                 %{type: %{kind: :Literal, type: :atom}, body: "bar", kind: :Value}
               ],
               kind: :Value
             }
           } == Attrs.parse(ast)
  end

  test "parse attr with nil" do
    {:ok, ast} =
      """
      @options_schema nil
      """
      |> Code.string_to_quoted()

    assert %{
             body: "options_schema",
             kind: :Attr,
             value: %{kind: :Value, type: %{kind: :Literal, type: :atom}, body: "nil"}
           } == Attrs.parse(ast)
  end

  test "parse attr with struct" do
    {:ok, ast} =
      """
      @attribute %{foo: :bar}
      """
      |> Code.string_to_quoted()

    assert %{
             body: "attribute",
             kind: :Attr,
             value: %{
               keyword: [
                 %{
                   kind: :Value,
                   type: %{kind: :Structure, type: :tuple},
                   elements: [
                     %{type: %{kind: :Literal, type: :atom}, body: "foo", kind: :Value},
                     %{type: %{kind: :Literal, type: :atom}, body: "bar", kind: :Value}
                   ]
                 }
               ],
               kind: :Value,
               type: %{kind: :Structure, type: :map}
             }
           } == Attrs.parse(ast)
  end
end
