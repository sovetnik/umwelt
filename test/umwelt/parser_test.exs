defmodule Umwelt.ParserTest do
  use ExUnit.Case, async: true

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

  describe "reading ast" do
    test "read_ast when error" do
      assert {:error, "read failed"} ==
               Parser.read_ast({:error, "read failed"})
    end

    test "read_ast success", %{code: code} do
      assert {:ok,
              {
                :defmodule,
                [line: 1],
                [
                  {:__aliases__, [line: 1], [:Root]},
                  [
                    do: {
                      :__block__,
                      [],
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
                      ]
                    }
                  ]
                ]
              }} == Parser.read_ast({:ok, code})
    end
  end

  describe "parsing ast" do
    test "general example", %{code: code} do
      assert %{
               ["Root"] => %{
                 body: "Root",
                 context: ["Root"],
                 attrs: [
                   %{
                     value: %{
                       type: %{kind: :Literal, type: :atom},
                       body: "root_attribute",
                       kind: :Value
                     },
                     body: "root_attr",
                     kind: :Attr
                   }
                 ],
                 calls: [],
                 guards: [],
                 types: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "once", kind: :Variable}
                     ],
                     body: "root_one",
                     kind: :Function
                   },
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "twice", kind: :Variable}
                     ],
                     body: "root_two",
                     kind: :Function
                   }
                 ],
                 kind: :Root,
                 note: "Root description"
               },
               ["Root", "Foo"] => %{
                 body: "Foo",
                 context: ["Root", "Foo"],
                 attrs: [
                   %{
                     value: %{
                       type: %{kind: :Literal, type: :atom},
                       body: "baz_attribute",
                       kind: :Value
                     },
                     body: "baz_attr",
                     kind: :Attr
                   },
                   %{
                     value: %{
                       type: %{kind: :Literal, type: :atom},
                       body: "bar_attribute",
                       kind: :Value
                     },
                     body: "bar_attr",
                     kind: :Attr
                   }
                 ],
                 calls: [],
                 guards: [],
                 types: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "bar", kind: :Variable}
                     ],
                     body: "foo",
                     kind: :Function
                   }
                 ],
                 kind: :Concept,
                 note: "Foo description"
               },
               ["Root", "Foo", "Bar"] => %{
                 body: "Bar",
                 context: ["Root", "Foo", "Bar"],
                 attrs: [],
                 calls: [],
                 guards: [],
                 types: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "baz", kind: :Variable}
                     ],
                     body: "bar",
                     kind: :Function
                   }
                 ],
                 kind: :Concept,
                 note: "Bar description"
               },
               ["Root", "Foo", "Baz"] => %{
                 body: "Baz",
                 context: ["Root", "Foo", "Baz"],
                 attrs: [],
                 calls: [],
                 guards: [],
                 types: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: %{kind: :Literal, type: :anything}, body: "foo", kind: :Variable}
                     ],
                     body: "baz",
                     kind: :Function
                   }
                 ],
                 kind: :Concept,
                 note: "Baz description"
               }
             } ==
               {:ok, code}
               |> Parser.read_ast()
               |> Parser.parse_root()
    end

    test "weird pipe operator" do
      {:ok, ast} =
        """
          def bar(a, b) when a |> Kernel.and(b) do
            :baz
          end
        """
        |> Code.string_to_quoted()

      assert %{
               body: "when",
               kind: :Operator,
               left: %{
                 arguments: [
                   %{body: "a", kind: :Variable, type: %{kind: :Literal, type: :anything}},
                   %{body: "b", kind: :Variable, type: %{kind: :Literal, type: :anything}}
                 ],
                 body: "bar",
                 kind: :Call
               },
               right: %{
                 body: "and",
                 kind: :Operator,
                 left: %{body: "a", kind: :Variable, type: %{kind: :Literal, type: :anything}},
                 right: %{body: "b", kind: :Variable, type: %{kind: :Literal, type: :anything}}
               }
             } == Parser.parse(ast, [])
    end

    test "kernel operator" do
      {:ok, ast} =
        """
          def bar(a, b) when Kernel.and(a, b) do
            :baz
          end
        """
        |> Code.string_to_quoted()

      assert %{
               body: "when",
               kind: :Operator,
               left: %{
                 arguments: [
                   %{body: "a", kind: :Variable, type: %{kind: :Literal, type: :anything}},
                   %{body: "b", kind: :Variable, type: %{kind: :Literal, type: :anything}}
                 ],
                 body: "bar",
                 kind: :Call
               },
               right: %{
                 body: "and",
                 kind: :Operator,
                 left: %{body: "a", kind: :Variable, type: %{kind: :Literal, type: :anything}},
                 right: %{body: "b", kind: :Variable, type: %{kind: :Literal, type: :anything}}
               }
             } == Parser.parse(ast, [])
    end

    test "tuple pair" do
      {:ok, ast} = Code.string_to_quoted("{:ok, msg}")

      assert %{
               kind: :Value,
               type: %{kind: :Structure, type: :tuple},
               elements: [
                 %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
                 %{body: "msg", kind: :Variable, type: %{kind: :Literal, type: :anything}}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "string value" do
      {:ok, ast} = Code.string_to_quoted("\"foo\"")

      assert %{
               body: "foo",
               kind: :Value,
               type: %{kind: :Literal, type: :binary}
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "raw string" do
      {:ok, ast} = Code.string_to_quoted("<<1,2,3>>")

      assert %{
               kind: :Value,
               type: %{kind: :Structure, type: :bitstring},
               bits: [
                 %{type: %{kind: :Literal, type: :integer}, body: "1", kind: :Value},
                 %{type: %{kind: :Literal, type: :integer}, body: "2", kind: :Value},
                 %{type: %{kind: :Literal, type: :integer}, body: "3", kind: :Value}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "tuple value" do
      {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

      assert %{
               kind: :Value,
               type: %{kind: :Structure, type: :tuple},
               elements: [
                 %{body: "ok", kind: :Value, type: %{kind: :Literal, type: :atom}},
                 %{body: "13", kind: :Value, type: %{kind: :Literal, type: :integer}}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "value list with pipe" do
      {:ok, ast} = Code.string_to_quoted("[head | tail]")

      assert %{
               kind: :Value,
               type: %{kind: :Structure, type: :list},
               values: [
                 %{
                   body: "|",
                   kind: :Pipe,
                   left: %{
                     type: %{type: :anything, kind: :Literal},
                     body: "head",
                     kind: :Variable
                   },
                   right: [
                     %{type: %{type: :anything, kind: :Literal}, body: "tail", kind: :Variable}
                   ]
                 }
               ]
             } == Parser.parse(ast, [])
    end
  end
end
