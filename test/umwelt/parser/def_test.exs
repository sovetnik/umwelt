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
             arguments: [],
             body: "div",
             kind: :function
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
             arguments: [
               %{body: "a", kind: :literal, type: [:Variable]},
               %{body: "b", kind: :literal, type: [:Variable]}
             ],
             body: "div",
             kind: :function
           } == Def.parse(ast, [])
  end

  test "method call in argument" do
    {:ok, ast} =
      ~S"""
        def list_from_root(path, project \\ Mix.Project.config()[:app]) do
          Mix.Project.config()[:elixirc_paths]
          |> Enum.flat_map(&files_in(Path.join(&1, to_string(project))))
        end
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [
               %{body: "path", kind: :literal, type: [:Variable]},
               %{
                 default_arg: [
                   %{body: "project", kind: :literal, type: [:Variable]},
                   %{
                     struct: %{
                       call: [
                         %{body: "Elixir.Access", kind: :literal, type: [:Atom]},
                         %{body: "get", kind: :literal, type: [:Atom]}
                       ]
                     },
                     brackets: %{
                       key: %{body: "app", kind: :literal, type: [:Atom]},
                       from: %{
                         call: [
                           [:Mix, :Project],
                           %{body: "config", kind: :literal, type: [:Atom]}
                         ]
                       }
                     }
                   }
                 ]
               }
             ],
             body: "list_from_root",
             kind: :function
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
             arguments: [
               %{type: [:Variable], body: "ast", kind: :literal},
               %{type: [:Variable], body: "_aliases", kind: :literal}
             ],
             body: "parse_tuple_child",
             kind: :function,
             guards: %{
               body: "or",
               kind: :comparison,
               left: %{
                 body: "or",
                 kind: :comparison,
                 left: %{
                   body: "or",
                   kind: :comparison,
                   left: %{
                     guard: %{body: "is_atom", kind: :literal, type: [:Atom]},
                     target_arg: [%{body: "ast", kind: :literal, type: [:Variable]}]
                   },
                   right: %{
                     guard: %{body: "is_binary", kind: :literal, type: [:Atom]},
                     target_arg: [%{body: "ast", kind: :literal, type: [:Variable]}]
                   }
                 },
                 right: %{
                   guard: %{body: "is_integer", kind: :literal, type: [:Atom]},
                   target_arg: [%{body: "ast", kind: :literal, type: [:Variable]}]
                 }
               },
               right: %{
                 guard: %{body: "is_float", kind: :literal, type: [:Atom]},
                 target_arg: [%{body: "ast", kind: :literal, type: [:Variable]}]
               }
             }
           } == Def.parse(ast, [])
  end

  test "parse with or guard" do
    {:ok, ast} =
      """
      def foo(bar, baz)
        when is_integer(bar) or is_float(baz) do
          :good
      end
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [
               %{body: "bar", kind: :literal, type: [:Variable]},
               %{body: "baz", kind: :literal, type: [:Variable]}
             ],
             body: "foo",
             kind: :function,
             guards: %{
               body: "or",
               kind: :comparison,
               left: %{
                 guard: %{type: [:Atom], body: "is_integer", kind: :literal},
                 target_arg: [%{type: [:Variable], body: "bar", kind: :literal}]
               },
               right: %{
                 guard: %{body: "is_float", kind: :literal, type: [:Atom]},
                 target_arg: [%{body: "baz", kind: :literal, type: [:Variable]}]
               }
             }
           } == Def.parse(ast, [])
  end

  test "parse with many guards" do
    {:ok, ast} =
      """
      def foo(bar, baz)
        when is_integer(bar) when is_float(baz) do
          :good
      end
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [
               %{body: "bar", kind: :literal, type: [:Variable]},
               %{body: "baz", kind: :literal, type: [:Variable]}
             ],
             body: "foo",
             kind: :function,
             guards: [
               %{
                 guard: %{type: [:Atom], body: "is_integer", kind: :literal},
                 target_arg: [%{type: [:Variable], body: "bar", kind: :literal}]
               },
               %{
                 guard: %{type: [:Atom], body: "is_float", kind: :literal},
                 target_arg: [%{type: [:Variable], body: "baz", kind: :literal}]
               }
             ]
           } == Def.parse(ast, [])
  end

  test "parse with guard and default value" do
    {:ok, ast} =
      ~S"""
        def increase(num, add \\ 1)
          when is_integer(num) or is_float(num) do
            num + add
        end
      """
      |> Code.string_to_quoted()

    assert %{
             guards: %{
               body: "or",
               kind: :comparison,
               left: %{
                 guard: %{body: "is_integer", kind: :literal, type: [:Atom]},
                 target_arg: [%{body: "num", kind: :literal, type: [:Variable]}]
               },
               right: %{
                 guard: %{body: "is_float", kind: :literal, type: [:Atom]},
                 target_arg: [%{body: "num", kind: :literal, type: [:Variable]}]
               }
             },
             arguments: [
               %{type: [:Variable], body: "num", kind: :literal},
               %{
                 default_arg: [
                   %{type: [:Variable], body: "add", kind: :literal},
                   %{type: [:Integer], body: "1", kind: :literal}
                 ]
               }
             ],
             body: "increase",
             kind: :function
           } == Def.parse(ast, [])
  end
end
