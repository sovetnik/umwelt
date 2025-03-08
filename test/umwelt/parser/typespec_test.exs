defmodule Umwelt.Parser.TypespecTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{Call, Literal, Operator, Structure, Type, Value, Variable}
  alias Umwelt.Parser.Typespec

  describe "parse @spec" do
    test "simpliest case" do
      {:ok, ast} =
        """
        @spec function(integer) :: atom
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 name: "function",
                 arguments: [%Variable{type: %Literal{type: :anything}, body: "integer"}],
                 type: %Literal{type: :atom}
               }
             } == Typespec.parse(ast, [], [])
    end

    test "parse Struct.t" do
      {:ok, ast} =
        """
        @spec function(num :: integer) :: String.t
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 name: "function",
                 arguments: [%Variable{body: "num", type: %Literal{type: :integer}}],
                 type: %Call{context: ["String"], arguments: [], name: "t"}
               }
             } == Typespec.parse(ast, [], [])
    end

    test "good case" do
      {:ok, ast} =
        """
        @spec days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 arguments: [
                   %Variable{type: %Literal{type: :integer}, body: "year"},
                   %Variable{type: %Literal{type: :integer}, body: "month"},
                   %Variable{type: %Literal{type: :integer}, body: "day"}
                 ],
                 type: %Literal{type: :integer},
                 name: "days_since_epoch"
               }
             } == Typespec.parse(ast, [], [])
    end
  end

  describe "parse @type" do
    test "simpliest case" do
      {:ok, ast} =
        """
        @type type_name :: boolean
        """
        |> Code.string_to_quoted()

      assert %Type{name: "type_name", spec: %Literal{type: :boolean}} ==
               Typespec.parse(ast, [], [])
    end

    test "type call like" do
      {:ok, ast} =
        """
        @type word() :: String.t()
        """
        |> Code.string_to_quoted()

      assert %Type{
               name: "word",
               spec: %Call{name: "t", arguments: [], context: ["String"]}
             } == Typespec.parse(ast, [], [])
    end

    test "type or (alter)" do
      {:ok, ast} =
        """
        @spec validate(any, String.t()) ::
           {:ok, String.t()} | {:error, String.t()}
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 arguments: [
                   %Variable{type: %Literal{type: :anything}, body: "any"},
                   %Call{
                     name: "t",
                     type: %Literal{type: :anything},
                     context: ["String"],
                     arguments: [],
                     note: ""
                   }
                 ],
                 context: [],
                 name: "validate",
                 note: "",
                 type: %Operator{
                   left: %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Value{body: "ok", type: %Literal{type: :atom}},
                       %Call{
                         name: "t",
                         note: "",
                         arguments: [],
                         context: ["String"],
                         type: %Literal{type: :anything}
                       }
                     ]
                   },
                   name: "alter",
                   right: %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Value{body: "error", type: %Literal{type: :atom}},
                       %Call{
                         name: "t",
                         note: "",
                         arguments: [],
                         context: ["String"],
                         type: %Literal{type: :anything}
                       }
                     ]
                   }
                 }
               }
             } == Typespec.parse(ast, [], [])
    end

    test "complex type" do
      {:ok, ast} =
        """
        @type shape :: %{required(atom()) => simple_type() | estructura_type()}
        """
        |> Code.string_to_quoted()

      assert %Type{
               name: "shape",
               spec: %Structure{
                 type: %Literal{type: :map},
                 elements: [
                   %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Call{arguments: [%Call{arguments: [], name: "atom"}], name: "required"},
                       %Operator{
                         name: "alter",
                         left: %Call{arguments: [], name: "simple_type"},
                         right: %Call{arguments: [], name: "estructura_type"}
                       }
                     ]
                   }
                 ]
               }
             } == Typespec.parse(ast, [], [])
    end
  end
end
