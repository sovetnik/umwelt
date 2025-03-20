defmodule Umwelt.Parser.SignatureTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Call,
    Concept,
    Literal,
    Operator,
    Signature,
    Structure,
    Variable
  }

  alias Umwelt.Parser

  test "signature with default" do
    {:ok, ast} = Code.string_to_quoted("def foo(bar, baz \\\\ %{})")

    assert %Signature{
             body: %Call{
               name: "foo",
               type: %Literal{type: :anything},
               arguments: [
                 %Variable{body: "bar", type: %Literal{type: :anything}},
                 %Operator{
                   name: "default",
                   left: %Variable{body: "baz", type: %Literal{type: :anything}},
                   right: %Structure{type: %Literal{type: :map}, elements: []}
                 }
               ]
             }
           } == Parser.Signature.parse(ast, [], [])
  end

  test "private signature" do
    {:ok, ast} = Code.string_to_quoted("defp foo(bar)")

    assert %Signature{
             body: %Call{
               arguments: [
                 %Variable{body: "bar", type: %Literal{type: :anything}}
               ],
               name: "foo",
               type: %Literal{type: :anything}
             },
             private: true
           } == Parser.Signature.parse(ast, [], [])
  end

  test "signature with spec" do
    code = """
      defmodule Foo.Bar do
        @moduledoc "Finds abstract type of element"

        @spec type(any, String.t(), map) :: String.t()
        def type(foo, bar, baz \\\\ %{})
      end
    """

    assert %{
             ["Foo", "Bar"] => %Concept{
               functions: [
                 %Signature{
                   body: %Call{
                     name: "type",
                     arguments: [
                       %Variable{body: "foo", type: %Literal{type: :anything}},
                       %Variable{
                         body: "bar",
                         type: %Call{
                           name: "t",
                           context: ["String"],
                           type: %Literal{type: :anything}
                         }
                       },
                       %Variable{body: "baz", type: %Literal{type: :map}}
                     ],
                     type: %Call{name: "t", context: ["String"], type: %Literal{type: :anything}}
                   },
                   private: false
                 }
               ],
               name: "Bar",
               context: ["Foo", "Bar"],
               note: "Finds abstract type of element"
             }
           } == Parser.parse_raw(code)
  end
end
