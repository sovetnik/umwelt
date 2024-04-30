defmodule Umwelt.Parser.TypespecTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Typespec

  describe "parse @spec" do
    test "simpliest case" do
      {:ok, ast} =
        """
        @spec function(integer) :: atom
        """
        |> Code.string_to_quoted()

      assert %{
               kind: :Spec,
               spec: %{body: "atom", kind: :Variable, type: %{kind: :Literal, type: :anything}},
               type: %{
                 arguments: [
                   %{type: %{kind: :Literal, type: :anything}, body: "integer", kind: :Variable}
                 ],
                 body: "function",
                 kind: :Call
               }
             } == Typespec.parse(ast, [])
    end

    test "parse Struct.t" do
      {:ok, ast} =
        """
        @spec function(num :: integer) :: String.t
        """
        |> Code.string_to_quoted()

      assert %{
               kind: :Spec,
               spec: %{context: [:String], arguments: [], body: "t", kind: :Call},
               type: %{
                 arguments: [
                   %{body: "num", kind: :Variable, type: %{kind: :Literal, type: :integer}}
                 ],
                 body: "function",
                 kind: :Call
               }
             } == Typespec.parse(ast, [])
    end

    test "good case" do
      {:ok, ast} =
        """
        @spec days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
        """
        |> Code.string_to_quoted()

      assert %{
               kind: :Spec,
               spec: %{type: %{kind: :Literal, type: :anything}, body: "integer", kind: :Variable},
               type: %{
                 arguments: [
                   %{type: %{kind: :Literal, type: :integer}, body: "year", kind: :Variable},
                   %{type: %{kind: :Literal, type: :integer}, body: "month", kind: :Variable},
                   %{type: %{kind: :Literal, type: :integer}, body: "day", kind: :Variable}
                 ],
                 body: "days_since_epoch",
                 kind: :Call
               }
             } == Typespec.parse(ast, [])
    end
  end

  describe "parse @type" do
    test "simpliest case" do
      {:ok, ast} =
        """
        @type type_name :: boolean
        """
        |> Code.string_to_quoted()

      assert %{
               kind: :Type,
               spec: %{type: %{kind: :Literal, type: :anything}, body: "boolean", kind: :Variable},
               type: %{
                 type: %{kind: :Literal, type: :anything},
                 body: "type_name",
                 kind: :Variable
               }
             } == Typespec.parse(ast, [])
    end

    test "type call like" do
      {:ok, ast} =
        """
        @type word() :: String.t()
        """
        |> Code.string_to_quoted()

      assert %{
               kind: :Type,
               spec: %{body: "t", kind: :Call, arguments: [], context: [:String]},
               type: %{body: "word", kind: :Call, arguments: []}
             } == Typespec.parse(ast, [])
    end
  end
end
