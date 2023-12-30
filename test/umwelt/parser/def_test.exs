defmodule Umwelt.Parser.DefTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Def

  test "arity/0" do
    {:ok, ast} =
      """
        def div do
          :foo
        end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [],
             method: :div
           } == Def.parse(ast, [])
  end

  test "simpliest case" do
    {:ok, ast} =
      """
        def div(a, b) do
          a / b
        end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [
               %{body: "a", kind: [:Undefined]},
               %{body: "b", kind: [:Undefined]}
             ],
             method: :div
           } == Def.parse(ast, [])
  end

  test "parse with guards" do
    {:ok, ast} =
      """
      def parse_tuple_child(ast, _aliases)
        when is_atom(ast) or is_binary(ast) or
        is_integer(ast) or is_float(ast) do
          Parser.Literal.parse(ast)
      end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [%{body: "ast", kind: [:Undefined]}, %{body: "_aliases", kind: [:Undefined]}],
             method: :parse_tuple_child,
             guards: %{ast: [:is_float, :is_integer, :is_binary, :is_atom]}
           } == Def.parse(ast, [])
  end

  test "parse with guards and default value" do
    {:ok, ast} =
      """
      def increase(num, add \\\\ 1)
        when is_integer(num) or is_float(num) do
          num + add
      end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [
               %{body: "num", kind: [:Undefined]},
               %{
                 default_value: [
                   %{body: "add", kind: [:Undefined]},
                   %{body: "1", kind: [:Integer]}
                 ]
               }
             ],
             guards: %{num: [:is_float, :is_integer]},
             method: :increase
           } == Def.parse(ast, [])
  end
end
