defmodule Umwelt.Parser.StructureTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{Alias, Literal, Operator, Structure, Value, Variable}
  alias Umwelt.Parser

  import Umwelt.Parser.Structure, only: [is_structure: 1]

  describe "guard" do
    test "is_structure" do
      [:%, :%{}, :<<>>]
      |> Enum.map(&assert is_structure(&1))
    end
  end

  test "%{} map macro" do
    {:ok, ast} = Code.string_to_quoted("%{fizz: :buzz}")

    assert %Structure{
             elements: [
               %Structure{
                 elements: [
                   %Value{body: "fizz", type: %Literal{type: :atom}},
                   %Value{body: "buzz", type: %Literal{type: :atom}}
                 ],
                 type: %Literal{type: :tuple}
               }
             ],
             type: %Literal{type: :map}
           } == Parser.Structure.parse(ast, [], [])
  end

  describe "map" do
    test "%var{} map macro" do
      {:ok, ast} = Code.string_to_quoted("%var{fizz: :buzz}")

      assert %Structure{
               elements: [
                 %Structure{
                   elements: [
                     %Value{body: "fizz", type: %Literal{type: :atom}},
                     %Value{body: "buzz", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 }
               ],
               type: %Umwelt.Felixir.Variable{
                 type: %Umwelt.Felixir.Literal{type: :atom},
                 body: "var"
               }
             } == Parser.Structure.parse(ast, [], [])
    end

    test "typed %Buzz{} map macro" do
      {:ok, ast} = Code.string_to_quoted("%Foobar{fizz: :buzz}")

      assert %Structure{
               elements: [
                 %Structure{
                   elements: [
                     %Value{body: "fizz", type: %Literal{type: :atom}},
                     %Value{body: "buzz", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 }
               ],
               type: %Alias{name: "Foobar", path: ["Foobar"]}
             } == Parser.Structure.parse(ast, [], [])
    end

    test "%{ => } map macro" do
      {:ok, ast} = Code.string_to_quoted("%{:\"23\" => :foo, :bar => :baz}")

      assert %Structure{
               elements: [
                 %Structure{
                   elements: [
                     %Value{body: "23", type: %Literal{type: :atom}},
                     %Value{body: "foo", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 },
                 %Structure{
                   elements: [
                     %Value{body: "bar", type: %Literal{type: :atom}},
                     %Value{body: "baz", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 }
               ],
               type: %Literal{type: :map}
             } == Parser.Structure.parse(ast, [], [])
    end

    test "%{[] => } map macro" do
      {:ok, ast} = Code.string_to_quoted("%{[23] => :foo, :bar => :baz}")

      assert %Structure{
               elements: [
                 %Structure{
                   elements: [
                     %Structure{
                       type: %Literal{type: :list},
                       elements: [%Value{type: %Literal{type: :integer}, body: "23"}]
                     },
                     %Value{body: "foo", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 },
                 %Structure{
                   elements: [
                     %Value{body: "bar", type: %Literal{type: :atom}},
                     %Value{body: "baz", type: %Literal{type: :atom}}
                   ],
                   type: %Literal{type: :tuple}
                 }
               ],
               type: %Literal{type: :map}
             } == Parser.Structure.parse(ast, [], [])
    end
  end

  describe "tuple" do
    test "empty" do
      {:ok, ast} = Code.string_to_quoted("{}")

      assert %Structure{type: %Literal{type: :tuple}, elements: []} ==
               Parser.Structure.parse(ast, [], [])
    end

    test "tuple single" do
      {:ok, ast} = Code.string_to_quoted("{:foo}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [%Value{body: "foo", type: %Literal{type: :atom}}]
             } ==
               Parser.Structure.parse(ast, [], [])
    end

    test "tuple pair var" do
      {:ok, ast} = Code.string_to_quoted("{:ok, result}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Variable{body: "result", type: %Literal{type: :anything}}
               ]
             } == Parser.Structure.parse(ast, [], [])
    end

    test "tuple pair binary" do
      {:ok, ast} = Code.string_to_quoted("{:ok, \"binary\"}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Value{body: "binary", type: %Literal{type: :string}}
               ]
             } == Parser.Structure.parse(ast, [], [])
    end

    test "tuple pair integer" do
      {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Value{body: "13", type: %Literal{type: :integer}}
               ]
             } == Parser.Structure.parse(ast, [], [])
    end

    test "tuple pair matched" do
      {:ok, ast} = Code.string_to_quoted("{:ok, %Result{} = result}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Operator{
                   left: %Structure{
                     type: %Alias{name: "Result", path: ["Result"]},
                     elements: []
                   },
                   name: "match",
                   right: %Variable{
                     body: "result",
                     type: %Literal{type: :anything}
                   }
                 }
               ]
             } == Parser.Structure.parse(ast, [], [])
    end

    test "tuple triplet" do
      {:ok, ast} = Code.string_to_quoted("{:error, msg, details}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "error", type: %Literal{type: :atom}},
                 %Variable{body: "msg", type: %Literal{type: :anything}},
                 %Variable{body: "details", type: %Literal{type: :anything}}
               ]
             } == Parser.Structure.parse(ast, [], [])
    end
  end
end
