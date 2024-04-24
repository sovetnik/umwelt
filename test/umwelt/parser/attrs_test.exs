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
             spec: [
               {:"::", [line: 1],
                [
                  {:foobar, [line: 1],
                   [
                     {:"::", [line: 1], [{:fizz, [line: 1], nil}, {:atom, [line: 1], nil}]},
                     {:"::", [line: 1], [{:buzz, [line: 1], nil}, {:any, [line: 1], nil}]}
                   ]},
                  {:boolean, [line: 1], nil}
                ]}
             ]
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
             value: [
               %{type: [:Atom], body: "foo", kind: :Value},
               %{type: [:Atom], body: "bar", kind: :Value}
             ]
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
             value: %{kind: :Value, type: [:Atom], body: "nil"}
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
                   type: [:Tuple],
                   elements: [
                     %{type: [:Atom], body: "foo", kind: :Value},
                     %{type: [:Atom], body: "bar", kind: :Value}
                   ]
                 }
               ],
               kind: :Value,
               type: [:Map]
             }
           } == Attrs.parse(ast)
  end
end
