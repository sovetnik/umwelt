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
             kind: :call
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
             kind: :call
           } == Def.parse(ast, [])
  end

  test "method call in argument" do
    {:ok, ast} =
      ~S"""
        def list_from_root(path, project \\ Mix.Project.config(:dev)[:app]) do
          :good_path
        end
      """
      |> Code.string_to_quoted()

    assert %{
             body: "list_from_root",
             kind: :call,
             arguments: [
               %{body: "path", kind: :literal, type: [:Variable]},
               %{
                 default_arg: %{
                   arg: %{type: [:Variable], body: "project", kind: :literal},
                   default_value: %{
                     source: %{
                       arguments: [%{type: [:Atom], body: "dev", kind: :literal}],
                       body: "config",
                       context: [:Mix, :Project],
                       kind: :call
                     },
                     key: %{type: [:Atom], body: "app", kind: :literal},
                     kind: :access
                   }
                 }
               }
             ]
           } == Def.parse(ast, [])
  end

  describe "functions with guards" do
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
               body: "when",
               kind: :operator,
               left: %{
                 arguments: [
                   %{type: [:Variable], body: "ast", kind: :literal},
                   %{type: [:Variable], body: "_aliases", kind: :literal}
                 ],
                 body: "parse_tuple_child",
                 kind: :call
               },
               right: %{
                 body: "or",
                 kind: :operator,
                 left: %{
                   body: "or",
                   kind: :operator,
                   left: %{
                     body: "or",
                     kind: :operator,
                     left: %{
                       body: "is_atom",
                       kind: :call,
                       arguments: [
                         %{type: [:Variable], body: "ast", kind: :literal}
                       ]
                     },
                     right: %{
                       body: "is_binary",
                       kind: :call,
                       arguments: [
                         %{type: [:Variable], body: "ast", kind: :literal}
                       ]
                     }
                   },
                   right: %{
                     body: "is_integer",
                     kind: :call,
                     arguments: [
                       %{type: [:Variable], body: "ast", kind: :literal}
                     ]
                   }
                 },
                 right: %{
                   body: "is_float",
                   kind: :call,
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
               body: "when",
               kind: :operator,
               left: %{
                 arguments: [
                   %{type: [:Variable], body: "bar", kind: :literal},
                   %{type: [:Variable], body: "baz", kind: :literal}
                 ],
                 body: "foo",
                 kind: :call
               },
               right: %{
                 left: %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                   body: "is_float",
                   kind: :call
                 },
                 body: "or",
                 kind: :operator
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
               body: "when",
               kind: :operator,
               left: %{
                 arguments: [
                   %{type: [:Variable], body: "bar", kind: :literal},
                   %{type: [:Variable], body: "baz", kind: :literal}
                 ],
                 body: "foo",
                 kind: :call
               },
               right: %{
                 left: %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                   body: "is_float",
                   kind: :call
                 },
                 body: "when",
                 kind: :operator
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
               body: "when",
               kind: :operator,
               left: %{
                 body: "increase",
                 kind: :call,
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
                 kind: :operator,
                 left: %{
                   arguments: [%{type: [:Variable], body: "num", kind: :literal}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "num", kind: :literal}],
                   body: "is_float",
                   kind: :call
                 }
               }
             } == Def.parse(ast, [])
    end
  end
end
