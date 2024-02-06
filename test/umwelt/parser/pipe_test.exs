defmodule Umwelt.Parser.PipeTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser
  alias Umwelt.Parser.Pipe

  import Umwelt.Parser.Pipe,
    only: [
      is_left_operator: 1,
      is_right_operator: 1,
      is_pipe_operator: 1
    ]

  describe "pipe guards" do
    test "guard is_left_operator" do
      [:|>, :<<<, :>>>, :<<~, :~>>, :<~, :~>, :<~>, :<-]
      |> Enum.map(&assert is_left_operator(&1))
    end

    test "guard is_right_operator" do
      [:|]
      |> Enum.map(&assert is_right_operator(&1))
    end

    test "guard is_pipe_operator" do
      [:|>, :<<<, :>>>, :<<~, :~>>, :<~, :~>, :<~>, :<-, :|]
      |> Enum.map(&assert is_pipe_operator(&1))
    end
  end

  describe "examples" do
    test "pipe operator" do
      {:ok, piped_ast} = Code.string_to_quoted("bar |> foo(baz)")
      {:ok, unpiped_ast} = Code.string_to_quoted("foo(bar, baz)")

      assert Parser.parse(unpiped_ast, []) ==
               Pipe.parse(piped_ast, [])
    end

    test "literal list with head & tail" do
      {:ok, ast} = Code.string_to_quoted("head | tail")

      assert %{
               body: "|",
               kind: :pipe,
               values: [
                 %{type: [:Variable], body: "head", kind: :variable},
                 %{type: [:Variable], body: "tail", kind: :variable}
               ]
             } == Pipe.parse(ast, [])
    end

    test "other operator" do
      {:ok, ast} = Code.string_to_quoted("left <~> right")

      assert %{
               body: "<~>",
               kind: :pipe,
               values: [
                 %{type: [:Variable], body: "left", kind: :variable},
                 %{type: [:Variable], body: "right", kind: :variable}
               ]
             } == Pipe.parse(ast, [])
    end
  end
end
