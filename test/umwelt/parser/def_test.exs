defmodule Umwelt.Parser.DefTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Call,
    Concept,
    Function,
    Literal,
    Operator,
    Sigil,
    Signature,
    Structure,
    Value,
    Variable
  }

  alias Umwelt.Parser.{Def, Defmodule}

  test "arity/0" do
    {:ok, ast} =
      """
        def div do
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "div",
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "simpliest case" do
    {:ok, ast} =
      """
        def div(a, b) do
          a / b
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "div",
               arguments: [
                 %Variable{body: "a", type: %Literal{type: :anything}},
                 %Variable{body: "b", type: %Literal{type: :anything}}
               ]
             }
           } == Def.parse(ast, [], [])
  end

  test "keyword arg" do
    {:ok, ast} =
      """
        def boogie(a, b: c) do
          a / b
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "boogie",
               arguments: [
                 %Variable{body: "a", type: %Literal{type: :anything}},
                 %Structure{
                   type: %Literal{type: :list},
                   elements: [
                     %Structure{
                       type: %Literal{type: :tuple},
                       elements: [
                         %Value{body: "b", type: %Literal{type: :atom}},
                         %Variable{body: "c", type: %Literal{type: :anything}}
                       ]
                     }
                   ]
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "keyword list arg" do
    {:ok, ast} =
      """
        def woogie([a, b: c]) do
          a / b
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "woogie",
               arguments: [
                 %Structure{
                   type: %Literal{type: :list},
                   elements: [
                     %Variable{body: "a", type: %Literal{type: :anything}},
                     %Structure{
                       type: %Literal{type: :tuple},
                       elements: [
                         %Value{body: "b", type: %Literal{type: :atom}},
                         %Variable{body: "c", type: %Literal{type: :anything}}
                       ]
                     }
                   ]
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "typed variable Bar.Baz" do
    {:ok, ast} = Code.string_to_quoted("def foo(%Bar.Baz{} = bar)")

    assert %Signature{
             body: %Call{
               name: "foo",
               arguments: [
                 %Operator{
                   name: "match",
                   left: %Structure{type: %Alias{name: "Baz", path: ["Bar", "Baz"]}},
                   right: %Variable{body: "bar", type: %Literal{type: :anything}}
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "typed variable Bar.Baz aliased" do
    {:ok, ast} = Code.string_to_quoted("def foo(%Bar.Baz{} = bar)")

    assert %Signature{
             body: %Call{
               name: "foo",
               arguments: [
                 %Operator{
                   name: "match",
                   left: %Structure{
                     type: %Alias{name: "Baz", path: ["Foo", "Bar", "Baz"]}
                   },
                   right: %Variable{body: "bar", type: %Literal{type: :anything}}
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [%Alias{name: "Bar", path: ["Foo", "Bar"]}], [])
  end

  test "match in argument" do
    {:ok, ast} =
      """
        def foo({:ok, term} = result, count) do
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "foo",
               arguments: [
                 %Operator{
                   name: "match",
                   left: %Structure{
                     type: %Literal{type: :tuple},
                     elements: [
                       %Value{body: "ok", type: %Literal{type: :atom}},
                       %Variable{body: "term", type: %Literal{type: :anything}}
                     ]
                   },
                   right: %Variable{body: "result", type: %Literal{type: :anything}}
                 },
                 %Variable{body: "count", type: %Literal{type: :anything}}
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "list match [head | tail] value in argument" do
    {:ok, ast} =
      """
        def reverse([head | tail]), 
          do: reverse(tail, head)
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "reverse",
               arguments: [
                 %Structure{
                   type: %Literal{type: :list},
                   elements: [
                     %Operator{
                       name: "alter",
                       left: %Variable{body: "head", type: %Literal{type: :anything}},
                       right: %Variable{body: "tail", type: %Literal{type: :anything}}
                     }
                   ]
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "list match [head | tail] variable in argument" do
    {:ok, ast} =
      """
        def reverse([first | rest] = list), 
          do: reverse(tail, head)
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "reverse",
               arguments: [
                 %Operator{
                   name: "match",
                   left: %Structure{
                     type: %Literal{type: :list},
                     elements: [
                       %Operator{
                         name: "alter",
                         left: %Variable{body: "first", type: %Literal{type: :anything}},
                         right: %Variable{body: "rest", type: %Literal{type: :anything}}
                       }
                     ]
                   },
                   right: %Variable{body: "list", type: %Literal{type: :anything}}
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "method call in argument" do
    {:ok, ast} =
      ~S"""
        def list_from_root(path, project \\ Mix.Project.config(:dev)[:app]) do
          :good_path
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "list_from_root",
               arguments: [
                 %Variable{body: "path", type: %Literal{type: :anything}},
                 %Operator{
                   name: "default",
                   left: %Variable{body: "project", type: %Literal{type: :anything}},
                   right: %Operator{
                     name: "access",
                     left: %Call{
                       name: "config",
                       arguments: [%Value{body: "dev", type: %Literal{type: :atom}}],
                       context: ["Mix", "Project"],
                       type: %Literal{type: :anything}
                     },
                     right: %Value{body: "app", type: %Literal{type: :atom}}
                   }
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
  end

  test "operator binary concat in argument" do
    {:ok, ast} =
      ~S"""
        def extract(
           "sigil_" <>
             <<sigil::binary-size(1), delimiter::binary-size(1),
               mods::binary>>
         ) do
        end
      """
      |> Code.string_to_quoted()

    assert %Function{
             body: %Call{
               name: "extract",
               arguments: [
                 %Operator{
                   name: "<>",
                   left: %Value{
                     type: %Literal{type: :string},
                     body: "sigil_"
                   },
                   right: %Structure{
                     type: %Literal{type: :bitstring},
                     elements: []
                   }
                 }
               ],
               type: %Literal{type: :anything}
             }
           } == Def.parse(ast, [], [])
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

      assert %Function{
               body: %Operator{
                 name: "when",
                 left: %Call{
                   name: "parse_tuple_child",
                   arguments: [
                     %Variable{body: "ast", type: %Literal{type: :anything}},
                     %Variable{body: "_aliases", type: %Literal{type: :anything}}
                   ],
                   type: %Literal{type: :anything}
                 },
                 right: %Operator{
                   name: "or",
                   left: %Operator{
                     name: "or",
                     left: %Operator{
                       name: "or",
                       left: %Call{
                         name: "is_atom",
                         arguments: [%Variable{body: "ast", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       right: %Call{
                         name: "is_binary",
                         arguments: [%Variable{body: "ast", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       }
                     },
                     right: %Call{
                       name: "is_integer",
                       arguments: [%Variable{body: "ast", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     }
                   },
                   right: %Call{
                     name: "is_float",
                     arguments: [%Variable{body: "ast", type: %Literal{type: :anything}}],
                     type: %Literal{type: :anything}
                   }
                 }
               },
               private: false
             } == Def.parse(ast, [], [])
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

      assert %Function{
               body: %Operator{
                 name: "when",
                 left: %Call{
                   name: "foo",
                   arguments: [
                     %Variable{body: "bar", type: %Literal{type: :anything}},
                     %Variable{body: "baz", type: %Literal{type: :anything}}
                   ],
                   type: %Literal{type: :anything}
                 },
                 right: %Operator{
                   name: "or",
                   left: %Call{
                     name: "is_integer",
                     arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                     type: %Literal{type: :anything}
                   },
                   right: %Call{
                     name: "is_float",
                     arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                     type: %Literal{type: :anything}
                   }
                 }
               },
               private: false
             } == Def.parse(ast, [], [])
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

      assert %Function{
               body: %Operator{
                 name: "when",
                 left: %Call{
                   name: "foo",
                   arguments: [
                     %Variable{body: "bar", type: %Literal{type: :anything}},
                     %Variable{body: "baz", type: %Literal{type: :anything}}
                   ],
                   type: %Literal{type: :anything}
                 },
                 right: %Operator{
                   name: "when",
                   left: %Call{
                     name: "is_integer",
                     arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                     type: %Literal{type: :anything}
                   },
                   right: %Call{
                     name: "is_float",
                     arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                     type: %Literal{type: :anything}
                   }
                 }
               }
             } == Def.parse(ast, [], [])
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

      assert %Function{
               body: %Operator{
                 left: %Call{
                   arguments: [
                     %Variable{body: "num", type: %Literal{type: :anything}},
                     %Operator{
                       left: %Variable{body: "add", type: %Literal{type: :anything}},
                       name: "default",
                       right: %Value{body: "1", type: %Literal{type: :integer}}
                     }
                   ],
                   name: "increase",
                   type: %Literal{type: :anything}
                 },
                 name: "when",
                 right: %Operator{
                   left: %Call{
                     arguments: [%Variable{body: "num", type: %Literal{type: :anything}}],
                     name: "is_integer",
                     type: %Literal{type: :anything}
                   },
                   name: "or",
                   right: %Call{
                     arguments: [%Variable{body: "num", type: %Literal{type: :anything}}],
                     name: "is_float",
                     type: %Literal{type: :anything}
                   }
                 }
               }
             } == Def.parse(ast, [], [])
    end

    test "parse with guard and complex match" do
      {:ok, ast} =
        ~S"""
          defp apply_abstract(
                 %{element: %Element{kind: kind}} = abstract,
                 %{element: %Element{kind: "call"}} = node
              )
              when kind in ~w|concept external| do
            abstract |> qualified_call_ast(node)
          end
        """
        |> Code.string_to_quoted()

      assert %Function{
               body: %Operator{
                 left: %Call{
                   arguments: [
                     %Operator{
                       left: %Structure{
                         type: %Literal{type: :map},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{body: "element", type: %Literal{type: :atom}},
                               %Structure{
                                 type: %Alias{name: "Element", path: ["Element"]},
                                 elements: [
                                   %Structure{
                                     type: %Literal{type: :tuple},
                                     elements: [
                                       %Value{body: "kind", type: %Literal{type: :atom}},
                                       %Variable{body: "kind", type: %Literal{type: :anything}}
                                     ]
                                   }
                                 ]
                               }
                             ]
                           }
                         ]
                       },
                       name: "match",
                       right: %Variable{type: %Literal{type: :anything}, body: "abstract"}
                     },
                     %Operator{
                       left: %Structure{
                         type: %Literal{type: :map},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{body: "element", type: %Literal{type: :atom}},
                               %Structure{
                                 type: %Alias{name: "Element", path: ["Element"]},
                                 elements: [
                                   %Structure{
                                     type: %Literal{type: :tuple},
                                     elements: [
                                       %Value{body: "kind", type: %Literal{type: :atom}},
                                       %Value{body: "call", type: %Literal{type: :string}}
                                     ]
                                   }
                                 ]
                               }
                             ]
                           }
                         ]
                       },
                       name: "match",
                       right: %Variable{body: "node", type: %Literal{type: :anything}}
                     }
                   ],
                   name: "apply_abstract",
                   type: %Literal{type: :anything}
                 },
                 name: "when",
                 right: %Operator{
                   left: %Variable{type: %Literal{type: :anything}, body: "kind"},
                   name: "in",
                   right: %Sigil{mod: "sigil_w|", string: "concept external"}
                 }
               },
               private: true
             } == Def.parse(ast, [], [])
    end

    test "parse in module with guard and default value" do
      {:ok, ast} =
        ~S"""
        defmodule Foo.Bar do
          @moduledoc "Structures examples"
          def foobar(foo) when foo in [:bar, :baz]
        end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 name: "Bar",
                 note: "Structures examples",
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Operator{
                       name: "when",
                       left: %Call{
                         name: "foobar",
                         arguments: [%Variable{body: "foo", type: %Literal{type: :anything}}],
                         context: ["Foo", "Bar"],
                         type: %Literal{type: :anything}
                       },
                       right: %Operator{
                         name: "membership",
                         left: %Variable{body: "foo", type: %Literal{type: :anything}},
                         right: [
                           %Value{body: "bar", type: %Literal{type: :atom}},
                           %Value{body: "baz", type: %Literal{type: :atom}}
                         ]
                       }
                     },
                     private: false
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
    end
  end

  describe "multiple clauses" do
    test "matching arguments" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            @moduledoc "Matching examples"
            @doc "Head of fizzbuzz/2"
            @spec fizzbuzz(list, integer) :: atom
            def fizzbuzz(matches, number) 
            def fizzbuzz([], number), do: number
            def fizzbuzz([:fizz], number), do: :fizz
            def fizzbuzz([:buzz], number), do: :buzz
            def fizzbuzz([:fizz, :buzz], number), do: :fizzbuzz
          end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 context: ["Foo", "Bar"],
                 functions: [
                   %Signature{
                     body: %Call{
                       arguments: [
                         %Variable{body: "matches", type: %Literal{type: :list}},
                         %Variable{body: "number", type: %Literal{type: :integer}}
                       ],
                       name: "fizzbuzz",
                       type: %Literal{type: :atom}
                     },
                     note: "Head of fizzbuzz/2"
                   },
                   %Function{
                     body: %Call{
                       name: "fizzbuzz",
                       type: %Literal{type: :anything},
                       arguments: [
                         %Structure{type: %Literal{type: :list}},
                         %Variable{body: "number", type: %Literal{type: :anything}}
                       ]
                     }
                   },
                   %Function{
                     body: %Call{
                       name: "fizzbuzz",
                       type: %Literal{type: :anything},
                       arguments: [
                         %Structure{
                           type: %Literal{type: :list},
                           elements: [%Value{body: "fizz", type: %Literal{type: :atom}}]
                         },
                         %Variable{body: "number", type: %Literal{type: :anything}}
                       ]
                     }
                   },
                   %Function{
                     body: %Call{
                       arguments: [
                         %Structure{
                           elements: [%Value{body: "buzz", type: %Literal{type: :atom}}],
                           type: %Literal{type: :list}
                         },
                         %Variable{body: "number", type: %Literal{type: :anything}}
                       ],
                       name: "fizzbuzz",
                       type: %Literal{type: :anything}
                     }
                   },
                   %Function{
                     body: %Call{
                       arguments: [
                         %Structure{
                           elements: [
                             %Value{body: "fizz", type: %Literal{type: :atom}},
                             %Value{body: "buzz", type: %Literal{type: :atom}}
                           ],
                           type: %Literal{type: :list}
                         },
                         %Variable{body: "number", type: %Literal{type: :anything}}
                       ],
                       name: "fizzbuzz",
                       type: %Literal{type: :anything}
                     }
                   }
                 ],
                 name: "Bar",
                 note: "Matching examples"
               }
             ] == Defmodule.parse(ast, [])
    end

    #     test "multi clause with nil in args" do
    #       {:ok, ast} =
    #         ~S"""
    #           defmodule Foo do
    #             alias Foo.{Bar, Baz}

    #             def foobar(nil, _), do: nil

    #             def foobar(element_id, %Bar{} = baar),
    #             do: :baar

    #             def foobar(element_id, %Baz{} = baaz) when is_integer(element_id),
    #             do: :baaz
    #           end
    #         """
    #         |> Code.string_to_quoted()

    #       assert [
    #                %Concept{
    #                  aliases: [
    #                    %Alias{name: "Bar", path: ["Foo", "Bar"]},
    #                    %Alias{name: "Baz", path: ["Foo", "Baz"]}
    #                  ],
    #                  context: ["Foo"],
    #                  functions: [
    #                    %Function{
    #                      body: %Call{
    #                        arguments: [
    #                          %Value{body: "nil", type: %Literal{type: :atom}},
    #                          %Variable{type: %Literal{type: :anything}, body: "_"}
    #                        ],
    #                        name: "foobar",
    #                        type: %Literal{type: :anything}
    #                      }
    #                    },
    #                    %Function{
    #                      body: %Call{
    #                        arguments: [
    #                          %Variable{type: %Literal{type: :anything}, body: "element_id"},
    #                          %Operator{
    #                            name: "match",
    #                            left: %Structure{type: %Alias{name: "Bar", path: ["Foo", "Bar"]}},
    #                            right: %Variable{
    #                              type: %Alias{name: "Bar", path: ["Foo", "Bar"]},
    #                              body: "baar"
    #                            }
    #                          }
    #                        ],
    #                        name: "foobar",
    #                        type: %Literal{type: :anything}
    #                      }
    #                    },
    #                    %Function{
    #                      body: %Operator{
    #                        name: "when",
    #                        left: %Call{
    #                          name: "foobar",
    #                          type: %Literal{type: :anything},
    #                          context: ["Foo"],
    #                          arguments: [
    #                            %Variable{body: "element_id", type: %Literal{type: :anything}},
    #                            %Operator{
    #                              name: "match",
    #                              left: %Structure{type: %Alias{name: "Baz", path: ["Foo", "Baz"]}},
    #                              right: %Variable{
    #                                body: "baaz",
    #                                type: %Alias{name: "Baz", path: ["Foo", "Baz"]}
    #                              }
    #                            }
    #                          ]
    #                        },
    #                        right: %Call{
    #                          name: "is_integer",
    #                          type: %Literal{type: :anything},
    #                          context: ["Foo"],
    #                          arguments: [
    #                            %Variable{body: "element_id", type: %Literal{type: :anything}}
    #                          ]
    #                        }
    #                      }
    #                    }
    #                  ],
    #                  name: "Foo"
    #                }
    #              ] == Defmodule.parse(ast, [])
    #     end

    test "multiple inference types" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            alias Foo.Baz

            @spec specify(term :: First.t()) :: integer
            def specify(%First{} = term), do: :first
            @spec specify(term :: Second.t()) :: atom
            def specify(%Second{}), do: :second
            @spec specify(term :: Third.t()) :: Baz.t()
            def specify(%Third{}), do: :third
          end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 name: "Bar",
                 aliases: [%Alias{name: "Baz", path: ["Foo", "Baz"]}],
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       arguments: [
                         %Variable{
                           body: "term",
                           type: %Alias{path: ["First"], name: "First"}
                         }
                       ],
                       name: "specify",
                       type: %Literal{type: :integer}
                     }
                   },
                   %Function{
                     body: %Call{
                       arguments: [
                         %Structure{
                           type: %Alias{
                             name: "Second",
                             path: ["Second"]
                           }
                         }
                       ],
                       name: "specify",
                       type: %Literal{type: :atom}
                     }
                   },
                   %Function{
                     body: %Call{
                       arguments: [
                         %Structure{
                           type: %Alias{
                             name: "Third",
                             path: ["Third"]
                           }
                         }
                       ],
                       name: "specify",
                       type: %Alias{path: ["Baz"], name: "Baz"}
                     }
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
    end
  end
end
