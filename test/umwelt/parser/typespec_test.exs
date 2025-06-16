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
                 type: %Literal{type: :string}
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

    test "list in spec" do
      {:ok, ast} =
        """
        @spec expand_paths([String.t()], String.t()) :: [{String.t(), String.t()}]
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 arguments: [
                   %Structure{type: %Literal{type: :list}, elements: [%Literal{type: :string}]},
                   %Literal{type: :string}
                 ],
                 name: "expand_paths",
                 type: [
                   %Structure{
                     type: %Literal{type: :tuple},
                     elements: [%Literal{type: :string}, %Literal{type: :string}]
                   }
                 ]
               }
             } == Typespec.parse(ast, [], [])
    end

    test "tuple in spec" do
      {:ok, ast} =
        """
        @spec with_locale(String.t()) :: {String.t(), String.t()}
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 arguments: [
                   %Literal{type: :string}
                 ],
                 context: [],
                 name: "with_locale",
                 note: "",
                 type: %Structure{
                   type: %Literal{
                     type: :tuple
                   },
                   elements: [
                     %Literal{type: :string},
                     %Literal{type: :string}
                   ]
                 }
               }
             } == Typespec.parse(ast, [], [])
    end

    test "match nil in alter" do
      {:ok, ast} =
        """
        @spec lookup(String.t(), map(), keyword(), String.t() | nil) :: String.t()
        """
        |> Code.string_to_quoted()

      assert %{
               spec: %Call{
                 arguments: [
                   %Literal{type: :string},
                   %Call{name: "map", type: %Literal{type: :anything}},
                   %Call{name: "keyword", type: %Literal{type: :anything}},
                   %Operator{
                     name: "alter",
                     left: %Literal{type: :string},
                     right: %Value{body: "nil", type: %Literal{type: :atom}}
                   }
                 ],
                 name: "lookup",
                 type: %Literal{type: :string}
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
               spec: %Literal{type: :string}
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
                   %Literal{type: :string}
                 ],
                 context: [],
                 name: "validate",
                 note: "",
                 type: %Operator{
                   left: %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Value{body: "ok", type: %Literal{type: :atom}},
                       %Literal{type: :string}
                     ]
                   },
                   name: "alter",
                   right: %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Value{body: "error", type: %Literal{type: :atom}},
                       %Literal{type: :string}
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
