defmodule Umwelt.Parser.AttrsTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Attrs

  test "parse mdoc" do
    {:ok, ast} =
      """
        @moduledoc "Calculator"
      """
      |> Code.string_to_quoted()

    assert %{moduledoc: ["Calculator"]} ==
             Attrs.parse(ast)
  end

  test "parse doc" do
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
             value: [%{struct: [foo: :bar]}]
           } ==
             Attrs.parse(ast)
  end
end
