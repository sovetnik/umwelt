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
             function: :div
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
               %{body: "a", kind: [:Capture]},
               %{body: "b", kind: [:Capture]}
             ],
             function: :div
           } == Def.parse(ast, [])
  end

  test "method call in argument" do
    {:ok, ast} =
      """
        def list_from_root(path, project \\\\ Mix.Project.config()[:app]) do
          Mix.Project.config()[:elixirc_paths]
          |> Enum.flat_map(&files_in(Path.join(&1, to_string(project))))
        end
      """
      |> Code.string_to_quoted()

    assert %{
             args: [
               %{body: "path", kind: [:Capture]},
               %{
                 default_arg: [
                   %{body: "project", kind: [:Capture]},
                   %{
                     brackets: %{
                       key: %{body: "app", kind: [:Atom]},
                       from: %{call: [[:Mix, :Project], %{body: "config", kind: [:Atom]}]}
                     },
                     struct: %{
                       call: [
                         %{body: "Elixir.Access", kind: [:Atom]},
                         %{body: "get", kind: [:Atom]}
                       ]
                     }
                   }
                 ]
               }
             ],
             function: :list_from_root
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
             args: [
               %{body: "ast", kind: [:Capture]},
               %{body: "_aliases", kind: [:Capture]}
             ],
             function: :parse_tuple_child,
             guards: %{
               body: "or",
               kind: :comparsion,
               left: %{
                 body: "or",
                 kind: :comparsion,
                 left: %{
                   body: "or",
                   kind: :comparsion,
                   left: %{
                     guard: %{body: "is_atom", kind: [:Atom]},
                     target_arg: [%{body: "ast", kind: [:Capture]}]
                   },
                   right: %{
                     guard: %{body: "is_binary", kind: [:Atom]},
                     target_arg: [%{body: "ast", kind: [:Capture]}]
                   }
                 },
                 right: %{
                   guard: %{body: "is_integer", kind: [:Atom]},
                   target_arg: [%{body: "ast", kind: [:Capture]}]
                 }
               },
               right: %{
                 guard: %{body: "is_float", kind: [:Atom]},
                 target_arg: [%{body: "ast", kind: [:Capture]}]
               }
             }
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
               %{body: "num", kind: [:Capture]},
               %{
                 default_arg: [
                   %{body: "add", kind: [:Capture]},
                   %{body: "1", kind: [:Integer]}
                 ]
               }
             ],
             function: :increase,
             guards: %{
               body: "or",
               kind: :comparsion,
               left: %{
                 guard: %{body: "is_integer", kind: [:Atom]},
                 target_arg: [%{body: "num", kind: [:Capture]}]
               },
               right: %{
                 guard: %{body: "is_float", kind: [:Atom]},
                 target_arg: [%{body: "num", kind: [:Capture]}]
               }
             }
           } == Def.parse(ast, [])
  end
end
