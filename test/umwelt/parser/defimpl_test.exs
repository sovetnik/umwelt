defmodule Umwelt.Parser.DefimplTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Call,
    Function,
    Implement,
    Literal,
    Variable
  }

  alias Umwelt.Parser.Defimpl

  test "just implement" do
    {:ok, ast} =
      """
        defimpl Foo.Baz, for: Foo.Bar do
          @doc "implement fun of protocol"
          def foo(bar) do
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %Implement{
               name: "Baz",
               note: "impl Baz for Bar",
               context: ["Foo", "Bar", "Baz"],
               protocol: %Alias{name: "Baz", path: ["Foo", "Baz"]},
               subject: %Alias{name: "Bar", path: ["Foo", "Bar"]},
               functions: [
                 %Function{
                   note: "implement fun of protocol",
                   impl: true,
                   body: %Call{
                     name: "foo",
                     type: %Literal{type: :anything},
                     arguments: [
                       %Variable{
                         body: "bar",
                         type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                       }
                     ]
                   }
                 }
               ]
             }
           ] == Defimpl.parse(ast, [], [])
  end
end
