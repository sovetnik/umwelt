defmodule Umwelt.Parser.DefTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Def

  test "arity/0" do
    {:ok, ast} =
      """
        def div do
        end
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [],
             body: "div",
             kind: :Function
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
               %{body: "a", kind: :Variable, type: %{kind: :Literal, type: :anything}},
               %{body: "b", kind: :Variable, type: %{kind: :Literal, type: :anything}}
             ],
             body: "div",
             kind: :Function
           } == Def.parse(ast, [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("def foo(%Bar.Baz{} = bar)")

    assert %{
             arguments: [
               %{
                 body: "bar",
                 kind: :Variable,
                 type: %{name: :Baz, path: [:Bar, :Baz], kind: :Alias},
                 keyword: []
               }
             ],
             body: "foo",
             kind: :Function
           } == Def.parse(ast, [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("def foo(%Bar.Baz{} = bar)")

    assert %{
             body: "foo",
             kind: :Function,
             arguments: [
               %{
                 body: "bar",
                 keyword: [],
                 kind: :Variable,
                 type: %{
                   name: :Baz,
                   path: [:Foo, :Bar, :Baz],
                   kind: :Alias
                 }
               }
             ]
           } == Def.parse(ast, [%{name: :Bar, path: [:Foo, :Bar], kind: :Alias}])
  end

  test "match in argument" do
    {:ok, ast} =
      """
        def foo({:ok, term} = result, count) do
        end
      """
      |> Code.string_to_quoted()

    assert %{
             kind: :Function,
             body: "foo",
             arguments: [
               %{
                 body: "result",
                 kind: :Variable,
                 type: %{kind: :Structure, type: :tuple},
                 elements: [
                   %{type: %{kind: :Literal, type: :atom}, body: "ok", kind: :Value},
                   %{type: %{kind: :Literal, type: :anything}, body: "term", kind: :Variable}
                 ]
               },
               %{body: "count", kind: :Variable, type: %{kind: :Literal, type: :anything}}
             ]
           } == Def.parse(ast, [])
  end

  test "list match [head | tail] value in argument" do
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
                 kind: :Value,
                 type: %{kind: :Structure, type: :list},
                 head: %{type: %{kind: :Literal, type: :anything}, body: "head", kind: :Variable},
                 tail: %{type: %{kind: :Literal, type: :anything}, body: "tail", kind: :Variable}
               }
             ],
             body: "reverse",
             kind: :Function
           } == Def.parse(ast, [])
  end

  test "list match [head | tail] variable in argument" do
    {:ok, ast} =
      """
        def reverse([first | rest] = list), 
          do: reverse(tail, head)
      """
      |> Code.string_to_quoted()

    assert %{
             arguments: [
               %{
                 body: "list",
                 kind: :Variable,
                 type: %{kind: :Structure, type: :list},
                 values: [
                   %{
                     left: %{
                       type: %{type: :anything, kind: :Literal},
                       body: "first",
                       kind: :Variable
                     },
                     right: [
                       %{
                         type: %{type: :anything, kind: :Literal},
                         body: "rest",
                         kind: :Variable
                       }
                     ],
                     body: "|",
                     kind: :Pipe
                   }
                 ]
               }
             ],
             body: "reverse",
             kind: :Function
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
             kind: :Function,
             arguments: [
               %{body: "path", kind: :Variable, type: %{kind: :Literal, type: :anything}},
               %{
                 body: "project",
                 default: %{
                   key: %{type: %{kind: :Literal, type: :atom}, body: "app", kind: :Value},
                   source: %{
                     context: [:Mix, :Project],
                     arguments: [
                       %{type: %{kind: :Literal, type: :atom}, body: "dev", kind: :Value}
                     ],
                     body: "config",
                     kind: :Call
                   },
                   kind: :Access
                 },
                 kind: :Variable,
                 type: %{kind: :Literal, type: :anything}
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
               kind: :Operator,
               left: %{
                 arguments: [
                   %{type: %{kind: :Literal, type: :anything}, body: "ast", kind: :Variable},
                   %{type: %{kind: :Literal, type: :anything}, body: "_aliases", kind: :Variable}
                 ],
                 body: "parse_tuple_child",
                 kind: :Call
               },
               right: %{
                 body: "or",
                 kind: :Operator,
                 left: %{
                   body: "or",
                   kind: :Operator,
                   left: %{
                     body: "or",
                     kind: :Operator,
                     left: %{
                       body: "is_atom",
                       kind: :Call,
                       arguments: [
                         %{type: %{kind: :Literal, type: :anything}, body: "ast", kind: :Variable}
                       ]
                     },
                     right: %{
                       body: "is_binary",
                       kind: :Call,
                       arguments: [
                         %{type: %{kind: :Literal, type: :anything}, body: "ast", kind: :Variable}
                       ]
                     }
                   },
                   right: %{
                     body: "is_integer",
                     kind: :Call,
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "ast", kind: :Variable}
                     ]
                   }
                 },
                 right: %{
                   body: "is_float",
                   kind: :Call,
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "ast", kind: :Variable}
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
               kind: :Operator,
               left: %{
                 arguments: [
                   %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable},
                   %{type: %{kind: :Literal, type: :anything}, body: "baz", kind: :Variable}
                 ],
                 body: "foo",
                 kind: :Call
               },
               right: %{
                 left: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable}
                   ],
                   body: "is_integer",
                   kind: :Call
                 },
                 right: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "baz", kind: :Variable}
                   ],
                   body: "is_float",
                   kind: :Call
                 },
                 body: "or",
                 kind: :Operator
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
               kind: :Operator,
               left: %{
                 arguments: [
                   %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable},
                   %{type: %{kind: :Literal, type: :anything}, body: "baz", kind: :Variable}
                 ],
                 body: "foo",
                 kind: :Call
               },
               right: %{
                 left: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable}
                   ],
                   body: "is_integer",
                   kind: :Call
                 },
                 right: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "baz", kind: :Variable}
                   ],
                   body: "is_float",
                   kind: :Call
                 },
                 body: "when",
                 kind: :Operator
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
               kind: :Operator,
               left: %{
                 body: "increase",
                 kind: :Call,
                 arguments: [
                   %{type: %{kind: :Literal, type: :anything}, body: "num", kind: :Variable},
                   %{
                     body: "add",
                     default: %{
                       type: %{kind: :Literal, type: :integer},
                       body: "1",
                       kind: :Value
                     },
                     kind: :Variable,
                     type: %{kind: :Literal, type: :anything}
                   }
                 ]
               },
               right: %{
                 body: "or",
                 kind: :Operator,
                 left: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "num", kind: :Variable}
                   ],
                   body: "is_integer",
                   kind: :Call
                 },
                 right: %{
                   arguments: [
                     %{type: %{kind: :Literal, type: :anything}, body: "num", kind: :Variable}
                   ],
                   body: "is_float",
                   kind: :Call
                 }
               }
             } == Def.parse(ast, [])
    end
  end
end
