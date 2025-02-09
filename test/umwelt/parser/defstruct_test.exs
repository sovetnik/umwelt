defmodule Umwelt.Parser.DefstructTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{Alias, Call, Concept, Field, Literal, Structure, Type, Value}
  alias Umwelt.Parser.{Defmodule, Defstruct}

  test "just a module with derive attr" do
    {:ok, ast} =
      ~s| defstruct [:element, :tree] |
      |> Code.string_to_quoted()

    assert %{
             defstruct: [
               %Field{
                 name: "element",
                 type: %Literal{type: :anything},
                 value: %Value{type: %Literal{type: :atom}, body: "nil"}
               },
               %Field{
                 name: "tree",
                 type: %Literal{type: :anything},
                 value: %Value{type: %Literal{type: :atom}, body: "nil"}
               }
             ]
           } == Defstruct.parse(ast, [], [])
  end

  test "empty inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar module"
          alias Foo.Bar.Baz

          @type buzz :: Buzz.t()
          @type fizz() :: Fizz.t()
          @typedoc "just a word"
          @type word() :: String.t()
          @type t() :: %Foo.Bar{
                  buzz: buzz,
                  fizz: fizz(),
                  name: word(),
                  sentence: String.t(),
                  head: Baz.t(),
                  elements: list
               }

          defstruct buzz: "buzzy",
                    fizz: "fizzy",
                    name: "struct_name",
                    head: nil,
                    sentence: "holy shit!",
                    elements: []
          defmodule Baz do
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %Concept{
               context: ["Foo", "Bar"],
               name: "Bar",
               note: "Foobar module",
               aliases: [%Alias{name: "Baz", path: ~w|Foo Bar Baz|}],
               fields: [
                 %Field{
                   name: "buzz",
                   type: %Type{
                     name: "buzz",
                     spec: %Call{
                       name: "t",
                       type: %Literal{type: :anything},
                       context: ["Buzz"]
                     }
                   },
                   value: %Value{
                     body: "buzzy",
                     type: %Literal{type: :string}
                   }
                 },
                 %Field{
                   name: "fizz",
                   type: %Type{
                     name: "fizz",
                     doc: "",
                     spec: %Call{
                       name: "t",
                       type: %Literal{type: :anything},
                       context: ["Fizz"]
                     }
                   },
                   value: %Value{
                     body: "fizzy",
                     type: %Literal{type: :string}
                   }
                 },
                 %Field{
                   name: "name",
                   type: %Type{
                     doc: "",
                     name: "word",
                     spec: %Call{
                       name: "t",
                       type: %Literal{type: :anything},
                       context: ["String"]
                     }
                   },
                   value: %Value{
                     body: "struct_name",
                     type: %Literal{type: :string}
                   }
                 },
                 %Field{
                   name: "head",
                   type: %Alias{name: "Baz", path: ~w|Foo Bar Baz|},
                   value: %Value{
                     body: "nil",
                     type: %Literal{type: :atom}
                   }
                 },
                 %Field{
                   name: "sentence",
                   type: %Literal{type: :string},
                   value: %Umwelt.Felixir.Value{
                     type: %Umwelt.Felixir.Literal{type: :string},
                     body: "holy shit!"
                   }
                 },
                 %Field{
                   name: "elements",
                   type: %Literal{type: :list},
                   value: %Structure{
                     elements: [],
                     type: %Literal{type: :list}
                   }
                 }
               ],
               types: [
                 %Type{
                   name: "buzz",
                   spec: %Call{
                     name: "t",
                     context: ["Buzz"],
                     type: %Literal{type: :anything}
                   },
                   doc: ""
                 },
                 %Type{
                   name: "fizz",
                   spec: %Call{
                     name: "t",
                     context: ["Fizz"],
                     type: %Literal{type: :anything}
                   },
                   doc: ""
                 },
                 %Type{
                   name: "word",
                   spec: %Call{
                     name: "t",
                     context: ["String"],
                     type: %Literal{type: :anything}
                   },
                   doc: "just a word"
                 }
               ]
             },
             [%Concept{context: ["Foo", "Bar", "Baz"], name: "Baz"}]
           ] == Defmodule.parse(ast, [])
  end
end
