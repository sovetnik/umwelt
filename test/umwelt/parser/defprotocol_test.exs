defmodule Umwelt.Parser.DefprotocolTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Call,
    Literal,
    Protocol,
    Signature,
    Variable
  }

  alias Umwelt.Parser.Defprotocol

  test "just one signature" do
    {:ok, ast} =
      """
      defprotocol Foo.Bar do
        def unparse(t)
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Protocol{
               name: "Bar",
               note: "Bar protocol",
               context: ["Foo", "Bar"],
               signatures: [
                 %Signature{
                   body: %Call{
                     name: "unparse",
                     type: %Literal{type: :anything},
                     arguments: [%Variable{body: "t", type: %Literal{type: :anything}}]
                   }
                 }
               ]
             }
           ] == Defprotocol.parse(ast, [])
  end

  test "many signatures" do
    {:ok, ast} =
      """
      defprotocol Foo.Bar do
        def fizz(t)
        def buzz(t)
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Protocol{
               name: "Bar",
               note: "Bar protocol",
               context: ["Foo", "Bar"],
               aliases: [],
               signatures: [
                 %Signature{
                   body: %Call{
                     arguments: [
                       %Variable{
                         body: "t",
                         type: %Literal{type: :anything}
                       }
                     ],
                     context: [],
                     name: "fizz",
                     note: "",
                     type: %Literal{type: :anything}
                   },
                   note: "",
                   private: false
                 },
                 %Signature{
                   private: false,
                   body: %Call{
                     name: "buzz",
                     type: %Literal{type: :anything},
                     context: [],
                     arguments: [
                       %Variable{
                         body: "t",
                         type: %Literal{type: :anything}
                       }
                     ],
                     note: ""
                   },
                   note: ""
                 }
               ]
             }
           ] == Defprotocol.parse(ast, [])
  end

  test "expands aliases" do
    {:ok, ast} =
      """
      defprotocol Foo.Bar do
        @moduledoc "Unparses parsed to term"
        alias Foo.Baz
        @doc "unparsing"
        @spec unparse(t()) :: Baz.t()
        def unparse(t)
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Protocol{
               name: "Bar",
               note: "Unparses parsed to term",
               context: ["Foo", "Bar"],
               aliases: [%Alias{name: "Baz", path: ["Foo", "Baz"]}],
               signatures: [
                 %Signature{
                   body: %Call{
                     arguments: [
                       %Variable{
                         type: %Call{
                           type: %Literal{type: :anything},
                           context: ["Foo", "Bar"],
                           name: "t"
                         },
                         body: "t"
                       }
                     ],
                     name: "unparse",
                     type: %Alias{path: ["Baz"], name: "Baz"}
                   },
                   note: "unparsing"
                 }
               ]
             }
           ] == Defprotocol.parse(ast, [])
  end

  test "signature with complex spec" do
    {:ok, ast} =
      """
      defprotocol Foo.Bar do
      @spec foobar(
          t(),
          {term(), integer() | list()},
          {integer(), list()}
        ) :: :ok
      def foobar(foo, bar, baz)
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Protocol{
               name: "Bar",
               note: "Bar protocol",
               context: ["Foo", "Bar"],
               signatures: [
                 %Signature{
                   body: %Call{
                     arguments: [
                       %Umwelt.Felixir.Variable{
                         body: "foo",
                         type: %Umwelt.Felixir.Call{
                           type: %Umwelt.Felixir.Literal{type: :anything},
                           context: ["Foo", "Bar"],
                           name: "t"
                         }
                       },
                       %Umwelt.Felixir.Variable{
                         type: %Umwelt.Felixir.Literal{type: :tuple},
                         body: "bar"
                       },
                       %Umwelt.Felixir.Variable{
                         type: %Umwelt.Felixir.Literal{type: :tuple},
                         body: "baz"
                       }
                     ],
                     name: "foobar",
                     type: %Umwelt.Felixir.Value{
                       type: %Umwelt.Felixir.Literal{type: :atom},
                       body: "ok"
                     }
                   }
                 }
               ]
             }
           ] == Defprotocol.parse(ast, [])
  end
end
