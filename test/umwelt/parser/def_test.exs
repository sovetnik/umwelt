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
          :good_path
        end
      """
      |> Code.string_to_quoted()

    assert %{
             body: "list_from_root",
             kind: :function,
             arguments: [
               %{body: "path", kind: :literal, type: [:Variable]},
               %{
                 default_arg: %{
                   arg: %{type: [:Variable], body: "project", kind: :literal},
                   default_value: %{
                     source: %{
                       source: %{type: [:Atom], body: ".", kind: :literal},
                       brackets: %{
                         key: %{type: [:Atom], body: "get", kind: :literal},
                         from: %{type: [:Atom], body: "Elixir.Access", kind: :literal}
                       }
                     },
                     brackets: %{
                       key: %{type: [:Atom], body: "app", kind: :literal},
                       from: %{
                         context: [:Mix, :Project],
                         body: "config",
                         kind: :call,
                         arguments: []
                       }
                     }
                   }
                 }
               }
             ]
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
             kind: :when,
             left: %{
               arguments: [
                 %{type: [:Variable], body: "ast", kind: :literal},
                 %{type: [:Variable], body: "_aliases", kind: :literal}
               ],
               body: "parse_tuple_child",
               kind: :function
             },
             right: %{
               body: "or",
               kind: :comparison,
               left: %{
                 body: "or",
                 kind: :comparison,
                 left: %{
                   body: "or",
                   kind: :comparison,
                   left: %{
                     body: "is_atom",
                     kind: :function,
                     arguments: [
                       %{type: [:Variable], body: "ast", kind: :literal}
                     ]
                   },
                   right: %{
                     body: "is_binary",
                     kind: :function,
                     arguments: [
                       %{type: [:Variable], body: "ast", kind: :literal}
                     ]
                   }
                 },
                 right: %{
                   body: "is_integer",
                   kind: :function,
                   arguments: [
                     %{type: [:Variable], body: "ast", kind: :literal}
                   ]
                 }
               },
               right: %{
                 body: "is_float",
                 kind: :function,
                 arguments: [
                   %{type: [:Variable], body: "ast", kind: :literal}
                 ]
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
             kind: :when,
             left: %{
               arguments: [
                 %{type: [:Variable], body: "bar", kind: :literal},
                 %{type: [:Variable], body: "baz", kind: :literal}
               ],
               body: "foo",
               kind: :function
             },
             right: %{
               left: %{
                 arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                 body: "is_integer",
                 kind: :function
               },
               right: %{
                 arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                 body: "is_float",
                 kind: :function
               },
               body: "or",
               kind: :comparison
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
             kind: :when,
             left: %{
               arguments: [
                 %{type: [:Variable], body: "bar", kind: :literal},
                 %{type: [:Variable], body: "baz", kind: :literal}
               ],
               body: "foo",
               kind: :function
             },
             right: %{
               left: %{
                 arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                 body: "is_integer",
                 kind: :function
               },
               right: %{
                 arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                 body: "is_float",
                 kind: :function
               },
               kind: :when
             }
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
             kind: :when,
             left: %{
               body: "increase",
               kind: :function,
               arguments: [
                 %{type: [:Variable], body: "num", kind: :literal},
                 %{
                   default_arg: %{
                     arg: %{type: [:Variable], body: "add", kind: :literal},
                     default_value: %{type: [:Integer], body: "1", kind: :literal}
                   }
                 }
               ]
             },
             right: %{
               body: "or",
               kind: :comparison,
               left: %{
                 arguments: [%{type: [:Variable], body: "num", kind: :literal}],
                 body: "is_integer",
                 kind: :function
               },
               right: %{
                 arguments: [%{type: [:Variable], body: "num", kind: :literal}],
                 body: "is_float",
                 kind: :function
               }
             }
           } == Def.parse(ast, [])
  end
end
