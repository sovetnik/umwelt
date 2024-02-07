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
               %{body: "a", kind: :variable, type: [:Variable]},
               %{body: "b", kind: :variable, type: [:Variable]}
             ],
             body: "div",
             kind: :call
           } == Def.parse(ast, [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("def foo( %Bar.Baz{} = bar)")

    assert %{
             arguments: [
               %{
                 body: "bar",
                 context: [:Bar, :Baz],
                 kind: :variable,
                 type: [:Map],
                 keyword: []
               }
             ],
             body: "foo",
             kind: :call
           } == Def.parse(ast, [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("def foo(%Bar.Baz{} = bar)")

    assert %{
             body: "foo",
             kind: :call,
             arguments: [
               %{
                 body: "bar",
                 context: [:Foo, :Bar, :Baz],
                 keyword: [],
                 kind: :variable,
                 type: [:Map]
               }
             ]
           } == Def.parse(ast, [[:Foo, :Bar]])
  end

  test "match in argument" do
    {:ok, ast} =
      """
        def foo({:ok, term} = result, count) do
        end
      """
      |> Code.string_to_quoted()

    assert %{
             kind: :call,
             body: "foo",
             arguments: [
               %{
                 body: "result",
                 kind: :variable,
                 type: [:Tuple],
                 elements: [
                   %{type: [:Atom], body: "ok", kind: :value},
                   %{type: [:Variable], body: "term", kind: :variable}
                 ]
               },
               %{body: "count", kind: :variable, type: [:Variable]}
             ]
           } == Def.parse(ast, [])
  end

  test "list match [head | tail] in argument" do
    {:ok, ast} =
      """
        def reverse([head | tail]), 
          do: reverse(tail, head)
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [
               %{
                 body: "_",
                 kind: :value,
                 type: [:List],
                 head: %{type: [:Variable], body: "head", kind: :variable},
                 tail: %{type: [:Variable], body: "tail", kind: :variable}
               }
             ],
             body: "reverse",
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
               %{body: "path", kind: :variable, type: [:Variable]},
               %{
                 body: "project",
                 default: %{
                   key: %{type: [:Atom], body: "app", kind: :value},
                   source: %{
                     context: [:Mix, :Project],
                     arguments: [%{type: [:Atom], body: "dev", kind: :value}],
                     body: "config",
                     kind: :call
                   },
                   kind: :access
                 },
                 kind: :variable,
                 type: [:Variable]
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
            Parser.value.parse(ast)
        end
        """
        |> Code.string_to_quoted()

      assert %{
               body: "when",
               kind: :operator,
               left: %{
                 arguments: [
                   %{type: [:Variable], body: "ast", kind: :variable},
                   %{type: [:Variable], body: "_aliases", kind: :variable}
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
                         %{type: [:Variable], body: "ast", kind: :variable}
                       ]
                     },
                     right: %{
                       body: "is_binary",
                       kind: :call,
                       arguments: [
                         %{type: [:Variable], body: "ast", kind: :variable}
                       ]
                     }
                   },
                   right: %{
                     body: "is_integer",
                     kind: :call,
                     arguments: [
                       %{type: [:Variable], body: "ast", kind: :variable}
                     ]
                   }
                 },
                 right: %{
                   body: "is_float",
                   kind: :call,
                   arguments: [
                     %{type: [:Variable], body: "ast", kind: :variable}
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
                   %{type: [:Variable], body: "bar", kind: :variable},
                   %{type: [:Variable], body: "baz", kind: :variable}
                 ],
                 body: "foo",
                 kind: :call
               },
               right: %{
                 left: %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
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
                   %{type: [:Variable], body: "bar", kind: :variable},
                   %{type: [:Variable], body: "baz", kind: :variable}
                 ],
                 body: "foo",
                 kind: :call
               },
               right: %{
                 left: %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
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
                   %{type: [:Variable], body: "num", kind: :variable},
                   %{
                     body: "add",
                     default: %{type: [:Integer], body: "1", kind: :value},
                     kind: :variable,
                     type: [:Variable]
                   }
                 ]
               },
               right: %{
                 body: "or",
                 kind: :operator,
                 left: %{
                   arguments: [%{type: [:Variable], body: "num", kind: :variable}],
                   body: "is_integer",
                   kind: :call
                 },
                 right: %{
                   arguments: [%{type: [:Variable], body: "num", kind: :variable}],
                   body: "is_float",
                   kind: :call
                 }
               }
             } == Def.parse(ast, [])
    end
  end
end
