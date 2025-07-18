defmodule Umwelt.ParserTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Attribute,
    Call,
    Concept,
    Function,
    Implement,
    Literal,
    Operator,
    Protocol,
    Root,
    Signature,
    Structure,
    Value,
    Variable
  }

  alias Umwelt.Parser

  setup do
    code = """
        defmodule Root do
          @moduledoc "Root description"
          @root_attr :root_attribute
          def root_one(once) do
            1
          end
          def root_two(twice) do
            2
          end
          defmodule Foo do
            @moduledoc "Foo description"
            @bar_attr :bar_attribute
            @baz_attr :baz_attribute
            def foo(bar) do
              :baz
            end
            defmodule Bar do
              @moduledoc "Bar description"
              def bar(baz) do
                :foo
              end
            end
            defmodule Baz do
              @moduledoc "Baz description"
              def baz(foo) do
                :bar
              end
            end
          end
        end
    """

    {:ok, code: code}
  end

  describe "parse_raw" do
    test "just a function" do
      code = """
        defmodule Foobar do
          def foo(bar, baz)
        end
      """

      assert %{
               ["Foobar"] => %Concept{
                 functions: [
                   %Signature{
                     body: %Call{
                       name: "foo",
                       arguments: [
                         %Variable{body: "bar", type: %Literal{type: :anything}},
                         %Variable{body: "baz", type: %Literal{type: :anything}}
                       ],
                       type: %Literal{type: :anything}
                     }
                   }
                 ],
                 context: ["Foobar"],
                 name: "Foobar"
               }
             } == Parser.parse_raw(code)
    end

    test "attr and function" do
      code = """
        defmodule Context do
          @fizz :buzz
          def foo(bar, baz)
        end
      """

      assert %{
               ["Context"] => %Concept{
                 functions: [
                   %Signature{
                     body: %Call{
                       name: "foo",
                       arguments: [
                         %Variable{body: "bar", type: %Literal{type: :anything}},
                         %Variable{body: "baz", type: %Literal{type: :anything}}
                       ],
                       type: %Literal{type: :anything}
                     }
                   }
                 ],
                 context: ["Context"],
                 name: "Context",
                 attrs: [
                   %Attribute{
                     name: "fizz",
                     value: %Value{type: %Literal{type: :atom}, body: "buzz"}
                   }
                 ]
               }
             } == Parser.parse_raw(code)
    end

    test "several modules", %{code: code} do
      assert %{
               ["Root"] => %Concept{
                 attrs: [
                   %Attribute{
                     name: "root_attr",
                     value: %Value{body: "root_attribute", type: %Literal{type: :atom}}
                   }
                 ],
                 context: ["Root"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "root_one",
                       arguments: [%Variable{body: "once", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "root_two",
                       arguments: [%Variable{body: "twice", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Root",
                 note: "Root description"
               },
               ["Root", "Foo"] => %Concept{
                 attrs: [
                   %Attribute{
                     name: "baz_attr",
                     value: %Value{body: "baz_attribute", type: %Literal{type: :atom}}
                   },
                   %Attribute{
                     name: "bar_attr",
                     value: %Value{body: "bar_attribute", type: %Literal{type: :atom}}
                   }
                 ],
                 context: ["Root", "Foo"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Foo",
                 note: "Foo description"
               },
               ["Root", "Foo", "Bar"] => %Concept{
                 context: ["Root", "Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "bar",
                       arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Bar",
                 note: "Bar description"
               },
               ["Root", "Foo", "Baz"] => %Concept{
                 context: ["Root", "Foo", "Baz"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "baz",
                       arguments: [%Variable{body: "foo", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Baz",
                 note: "Baz description"
               }
             } == Parser.parse_raw(code)
    end

    test "parsing error", %{} do
      assert {:error,
              {[
                 opening_delimiter: :do,
                 expected_delimiter: :end,
                 line: 1,
                 column: 9,
                 end_line: 1,
                 end_column: 11
               ], "missing terminator: end", ""}} == Parser.parse_raw("def foo do")
    end
  end

  describe "reading ast" do
    test "read_ast when error" do
      assert {:error, "read failed"} ==
               Parser.read_ast({:error, "read failed"})
    end

    test "read_ast success", %{code: code} do
      assert {:ok,
              {:defmodule, [line: 1],
               [
                 {:__aliases__, [line: 1], [:Root]},
                 [
                   do:
                     {:__block__, [],
                      [
                        {:@, [line: 2], [{:moduledoc, [line: 2], ["Root description"]}]},
                        {:@, [line: 3], [{:root_attr, [line: 3], [:root_attribute]}]},
                        {:def, [line: 4],
                         [{:root_one, [line: 4], [{:once, [line: 4], nil}]}, [do: 1]]},
                        {:def, [line: 7],
                         [{:root_two, [line: 7], [{:twice, [line: 7], nil}]}, [do: 2]]},
                        {:defmodule, [line: 10],
                         [
                           {:__aliases__, [line: 10], [:Foo]},
                           [
                             do:
                               {:__block__, [],
                                [
                                  {:@, [line: 11],
                                   [{:moduledoc, [line: 11], ["Foo description"]}]},
                                  {:@, [line: 12], [{:bar_attr, [line: 12], [:bar_attribute]}]},
                                  {:@, [line: 13], [{:baz_attr, [line: 13], [:baz_attribute]}]},
                                  {:def, [line: 14],
                                   [{:foo, [line: 14], [{:bar, [line: 14], nil}]}, [do: :baz]]},
                                  {:defmodule, [line: 17],
                                   [
                                     {:__aliases__, [line: 17], [:Bar]},
                                     [
                                       do:
                                         {:__block__, [],
                                          [
                                            {:@, [line: 18],
                                             [{:moduledoc, [line: 18], ["Bar description"]}]},
                                            {:def, [line: 19],
                                             [
                                               {:bar, [line: 19], [{:baz, [line: 19], nil}]},
                                               [do: :foo]
                                             ]}
                                          ]}
                                     ]
                                   ]},
                                  {:defmodule, [line: 23],
                                   [
                                     {:__aliases__, [line: 23], [:Baz]},
                                     [
                                       do:
                                         {:__block__, [],
                                          [
                                            {:@, [line: 24],
                                             [{:moduledoc, [line: 24], ["Baz description"]}]},
                                            {:def, [line: 25],
                                             [
                                               {:baz, [line: 25], [{:foo, [line: 25], nil}]},
                                               [do: :bar]
                                             ]}
                                          ]}
                                     ]
                                   ]}
                                ]}
                           ]
                         ]}
                      ]}
                 ]
               ]}} == Parser.read_ast({:ok, code})
    end
  end

  describe "parsing ast" do
    test "general example", %{code: code} do
      assert %{
               ["Root"] => %Root{
                 attrs: [
                   %Attribute{
                     name: "root_attr",
                     value: %Value{body: "root_attribute", type: %Literal{type: :atom}}
                   }
                 ],
                 context: ["Root"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "root_one",
                       arguments: [%Variable{body: "once", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "root_two",
                       arguments: [%Variable{body: "twice", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Root",
                 note: "Root description"
               },
               ["Root", "Foo"] => %Concept{
                 attrs: [
                   %Attribute{
                     name: "baz_attr",
                     value: %Value{body: "baz_attribute", type: %Literal{type: :atom}}
                   },
                   %Attribute{
                     name: "bar_attr",
                     value: %Value{body: "bar_attribute", type: %Literal{type: :atom}}
                   }
                 ],
                 context: ["Root", "Foo"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Foo",
                 note: "Foo description"
               },
               ["Root", "Foo", "Bar"] => %Concept{
                 context: ["Root", "Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "bar",
                       arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Bar",
                 note: "Bar description"
               },
               ["Root", "Foo", "Baz"] => %Concept{
                 context: ["Root", "Foo", "Baz"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "baz",
                       arguments: [%Variable{body: "foo", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   }
                 ],
                 name: "Baz",
                 note: "Baz description"
               }
             } ==
               {:ok, code}
               |> Parser.read_ast()
               |> Parser.parse_root()
               |> Parser.index_deep()
    end

    test "weird pipe operator" do
      {:ok, ast} =
        """
          def bar(a, b) when a |> Kernel.and(b) do
            :baz
          end
        """
        |> Code.string_to_quoted()

      assert %Function{
               body: %Operator{
                 name: "when",
                 left: %Call{
                   name: "bar",
                   arguments: [
                     %Variable{body: "a", type: %Literal{type: :anything}},
                     %Variable{body: "b", type: %Literal{type: :anything}}
                   ],
                   type: %Literal{type: :anything}
                 },
                 right: %Operator{
                   name: "and",
                   left: %Variable{body: "a", type: %Literal{type: :anything}},
                   right: %Variable{body: "b", type: %Literal{type: :anything}}
                 }
               },
               private: false
             } == Parser.parse(ast, [], [])
    end

    test "Erlang operator" do
      # not is_nil(:erlang.map_get(:finished_at, phase))
      {:ok, ast} =
        """
          def handle(term) when :erlang.map_get(:finished_at, term) do
            :baz
          end
        """
        |> Code.string_to_quoted()

      assert %Function{
               body: %Operator{
                 left: %Call{
                   arguments: [%Variable{body: "term", type: %Literal{type: :anything}}],
                   name: "handle",
                   type: %Literal{type: :anything}
                 },
                 name: "when",
                 right: %Call{
                   name: "map_get",
                   arguments: [
                     %Value{body: "finished_at", type: %Literal{type: :atom}},
                     %Variable{body: "term", type: %Literal{type: :anything}}
                   ],
                   context: %Value{type: %Literal{type: :atom}, body: "erlang"},
                   type: %Literal{type: :anything}
                 }
               }
             } == Parser.parse(ast, [], [])
    end

    test "kernel operator" do
      {:ok, ast} =
        """
          def bar(a, b) when Kernel.and(a, b) do
            :baz
          end
        """
        |> Code.string_to_quoted()

      assert %Function{
               body: %Operator{
                 name: "when",
                 left: %Call{
                   name: "bar",
                   arguments: [
                     %Variable{body: "a", type: %Literal{type: :anything}},
                     %Variable{body: "b", type: %Literal{type: :anything}}
                   ],
                   type: %Literal{type: :anything}
                 },
                 right: %Operator{
                   name: "and",
                   left: %Variable{body: "a", type: %Literal{type: :anything}},
                   right: %Variable{body: "b", type: %Literal{type: :anything}}
                 }
               },
               private: false
             } == Parser.parse(ast, [], [])
    end

    test "tuple pair" do
      {:ok, ast} = Code.string_to_quoted("{:ok, msg}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Variable{body: "msg", type: %Literal{type: :anything}}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]], [])
    end

    test "string value" do
      {:ok, ast} = Code.string_to_quoted("\"foo\"")

      assert %Value{body: "foo", type: %Literal{type: :string}} ==
               Parser.parse(ast, [[:Foo, :Bar]], [])
    end

    test "raw string" do
      {:ok, ast} = Code.string_to_quoted("<<1,2,3>>")

      assert %Structure{
               type: %Literal{type: :bitstring},
               elements: [
                 %Value{type: %Literal{type: :integer}, body: "1"},
                 %Value{type: %Literal{type: :integer}, body: "2"},
                 %Value{type: %Literal{type: :integer}, body: "3"}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]], [])
    end

    test "tuple value" do
      {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

      assert %Structure{
               type: %Literal{type: :tuple},
               elements: [
                 %Value{body: "ok", type: %Literal{type: :atom}},
                 %Value{body: "13", type: %Literal{type: :integer}}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]], [])
    end

    test "value list with pipe" do
      {:ok, ast} = Code.string_to_quoted("[head | tail]")

      assert %Structure{
               type: %Literal{type: :list},
               elements: [
                 %Operator{
                   left: %Variable{body: "head", type: %Literal{type: :anything}},
                   right: %Variable{body: "tail", type: %Literal{type: :anything}},
                   name: "alter"
                 }
               ]
             } == Parser.parse(ast, [], [])
    end
  end

  describe "defprotocol & defimpl" do
    test "in separate modules" do
      {:ok, ast} =
        """
        defmodule Foo.Bar do
          @moduledoc "Foobar module"
          @spec baz(t()) :: map()
          def baz(t)
        end

        defprotocol Foo.Baz do
          def baz(t)
        end

        defimpl Foo.Baz, for: Foo.Bar do
          def baz(foo, types) do
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               [
                 %Concept{
                   name: "Bar",
                   note: "Foobar module",
                   context: ["Foo", "Bar"],
                   functions: [
                     %Signature{
                       body: %Call{
                         name: "baz",
                         arguments: [
                           %Variable{
                             body: "t",
                             type: %Call{
                               name: "t",
                               context: ["Foo", "Bar"],
                               type: %Literal{type: :anything}
                             }
                           }
                         ],
                         type: %Literal{type: :map}
                       }
                     }
                   ]
                 }
               ],
               [
                 %Protocol{
                   name: "Baz",
                   note: "Baz protocol",
                   signatures: [
                     %Signature{
                       body: %Call{
                         name: "baz",
                         arguments: [%Variable{body: "t", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       }
                     }
                   ],
                   context: ["Foo", "Baz"]
                 }
               ],
               [
                 %Implement{
                   context: ["Foo", "Bar", "Baz"],
                   name: "Baz",
                   note: "impl Baz for Bar",
                   protocol: %Alias{name: "Baz", path: ["Foo", "Baz"]},
                   subject: %Alias{name: "Bar", path: ["Foo", "Bar"]},
                   functions: [
                     %Function{
                       impl: true,
                       body: %Call{
                         name: "baz",
                         type: %Literal{type: :anything},
                         arguments: [
                           %Variable{
                             body: "foo",
                             type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                           },
                           %Variable{body: "types", type: %Literal{type: :anything}}
                         ]
                       }
                     }
                   ]
                 }
               ]
             ] == Parser.parse(ast, [], [])
    end

    test "in one module" do
      {:ok, ast} =
        """
        defmodule Foo do
          @moduledoc "Foo concept"
          alias Foo.{Bar, Baz}
          defmodule Bar do
            @moduledoc "Bar concept"
            @spec baz(t()) :: map()
            def baz(t)
          end

          defprotocol Baz do
            def baz(t)
          end

          defimpl Baz, for: Bar do
            def baz(foo, types) do
            end
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 context: ["Foo"],
                 name: "Foo",
                 note: "Foo concept",
                 aliases: [
                   %Umwelt.Felixir.Alias{name: "Bar", path: ["Foo", "Bar"]},
                   %Umwelt.Felixir.Alias{name: "Baz", path: ["Foo", "Baz"]}
                 ]
               },
               [
                 %Concept{
                   name: "Bar",
                   note: "Bar concept",
                   context: ["Foo", "Bar"],
                   functions: [
                     %Signature{
                       body: %Call{
                         name: "baz",
                         arguments: [
                           %Variable{
                             body: "t",
                             type: %Call{
                               name: "t",
                               note: "",
                               context: ["Foo", "Bar"],
                               type: %Literal{type: :anything}
                             }
                           }
                         ],
                         type: %Literal{type: :map}
                       },
                       private: false
                     }
                   ]
                 }
               ],
               [
                 %Protocol{
                   name: "Baz",
                   note: "Baz protocol",
                   signatures: [
                     %Signature{
                       body: %Call{
                         name: "baz",
                         arguments: [%Variable{body: "t", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       private: false
                     }
                   ],
                   context: ["Foo", "Baz"]
                 }
               ],
               [
                 %Implement{
                   context: ["Foo", "Bar", "Baz"],
                   name: "Baz",
                   note: "impl Baz for Bar",
                   protocol: %Alias{name: "Baz", path: ["Foo", "Baz"]},
                   subject: %Alias{name: "Bar", path: ["Foo", "Bar"]},
                   functions: [
                     %Function{
                       private: false,
                       impl: true,
                       body: %Call{
                         name: "baz",
                         type: %Literal{
                           type: :anything
                         },
                         context: [],
                         arguments: [
                           %Variable{
                             body: "foo",
                             type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                           },
                           %Variable{
                             body: "types",
                             type: %Literal{type: :anything}
                           }
                         ]
                       },
                       note: ""
                     }
                   ]
                 }
               ]
             ] == Parser.parse_ast({:ok, ast})
    end

    test "in one module as __MODULE__" do
      {:ok, ast} =
        """
          defprotocol Foo.Baz do
            @spec foo(t()) :: boolean()
            def foo(t)
          end

          defmodule Foo.Bar do
            @moduledoc "Bar concept"

            alias Foo.Baz  


            defimpl Baz, for: __MODULE__ do
              def foo(bar) do
              end
            end
          end
        """
        |> Code.string_to_quoted()

      assert %{
               ["Foo", "Bar"] => %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 aliases: [%Alias{name: "Baz", path: ["Foo", "Baz"]}],
                 note: "Bar concept"
               },
               ["Foo", "Bar", "Baz"] => %Implement{
                 name: "Baz",
                 note: "impl Baz for Bar",
                 context: ["Foo", "Bar", "Baz"],
                 protocol: %Alias{name: "Baz", path: ["Foo", "Baz"]},
                 subject: %Alias{name: "Bar", path: ["Foo", "Bar"]},
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [
                         %Variable{body: "bar", type: %Alias{name: "Bar", path: ["Foo", "Bar"]}}
                       ],
                       type: %Literal{type: :anything}
                     },
                     impl: true
                   }
                 ]
               },
               ["Foo", "Baz"] => %Protocol{
                 name: "Baz",
                 context: ["Foo", "Baz"],
                 signatures: [
                   %Signature{
                     body: %Call{
                       name: "foo",
                       arguments: [
                         %Variable{
                           body: "t",
                           type: %Call{
                             name: "t",
                             context: ["Foo", "Baz"],
                             type: %Literal{type: :anything}
                           }
                         }
                       ],
                       type: %Literal{type: :boolean}
                     },
                     private: false
                   }
                 ],
                 note: "Baz protocol"
               }
             } ==
               Parser.parse_ast({:ok, ast})
               |> Parser.index_deep()
    end
  end
end
