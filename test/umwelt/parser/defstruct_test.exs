defmodule Umwelt.Parser.DefstructTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defstruct

  test "just a module with derive attr" do
    {:ok, ast} =
      ~s|
          defstruct [:element, :tree]
        |
      |> Code.string_to_quoted()

    assert %{
             defstruct: [
               %{
                 body: "element",
                 kind: :Field,
                 type: %{kind: :Literal, type: :anything},
                 value: %{type: %{type: :atom, kind: :Literal}, body: "nil", kind: :Value}
               },
               %{
                 body: "tree",
                 kind: :Field,
                 type: %{kind: :Literal, type: :anything},
                 value: %{type: %{type: :atom, kind: :Literal}, body: "nil", kind: :Value}
               }
             ]
           } == Defstruct.parse(ast, [])
  end
end
