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

  test "parse attr with struct" do
    {:ok, ast} =
      """
      @attr %{foo: :bar}
      """
      |> Code.string_to_quoted()

    assert %{
             body: "attr",
             kind: :attr,
             value: [
               %{
                 body: :map,
                 context: [],
                 keyword: [
                   %{
                     body: :tuple,
                     kind: :structure,
                     elements: [
                       %{type: [:Atom], body: "foo", kind: :literal},
                       %{type: [:Atom], body: "bar", kind: :literal}
                     ]
                   }
                 ],
                 kind: :structure
               }
             ]
           } == Attrs.parse(ast)
  end
end
