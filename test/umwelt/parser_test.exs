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
               [:Root] => %{
                 body: "Root",
                 context: [:Root],
                 attrs: [
                   %{
                     value: [%{type: [:Atom], body: "root_attribute", kind: :value}],
                     body: "root_attr",
                     kind: :attr
                   }
                 ],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "once", kind: :variable}],
                     body: "root_one",
                     kind: :call
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "twice", kind: :variable}],
                     body: "root_two",
                     kind: :call
                   }
                 ],
                 kind: :space,
                 note: "Root description"
               },
               [:Root, :Foo] => %{
                 body: "Foo",
                 context: [:Root, :Foo],
                 attrs: [
                   %{
                     value: [%{type: [:Atom], body: "baz_attribute", kind: :value}],
                     body: "baz_attr",
                     kind: :attr
                   },
                   %{
                     value: [%{type: [:Atom], body: "bar_attribute", kind: :value}],
                     body: "bar_attr",
                     kind: :attr
                   }
                 ],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                     body: "foo",
                     kind: :call
                   }
                 ],
                 kind: :space,
                 note: "Foo description"
               },
               [:Root, :Foo, :Bar] => %{
                 body: "Bar",
                 context: [:Root, :Foo, :Bar],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
                     body: "bar",
                     kind: :call
                   }
                 ],
                 kind: :space,
                 note: "Bar description"
               },
               [:Root, :Foo, :Baz] => %{
                 body: "Baz",
                 context: [:Root, :Foo, :Baz],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "foo", kind: :variable}],
                     body: "baz",
                     kind: :call
                   }
                 ],
                 kind: :space,
                 note: "Baz description"
               }
             } ==
               {:ok, code}
               |> Parser.read_ast()
               |> Parser.parse()
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
               kind: :operator,
               left: %{
                 arguments: [
                   %{body: "a", kind: :variable, type: [:Variable]},
                   %{body: "b", kind: :variable, type: [:Variable]}
                 ],
                 body: "bar",
                 kind: :call
               },
               right: %{
                 body: "and",
                 kind: :operator,
                 left: %{body: "a", kind: :variable, type: [:Variable]},
                 right: %{body: "b", kind: :variable, type: [:Variable]}
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
               kind: :operator,
               left: %{
                 arguments: [
                   %{body: "a", kind: :variable, type: [:Variable]},
                   %{body: "b", kind: :variable, type: [:Variable]}
                 ],
                 body: "bar",
                 kind: :call
               },
               right: %{
                 body: "and",
                 kind: :operator,
                 left: %{body: "a", kind: :variable, type: [:Variable]},
                 right: %{body: "b", kind: :variable, type: [:Variable]}
               }
             } == Parser.parse(ast, [])
    end

    test "tuple pair" do
      {:ok, ast} = Code.string_to_quoted("{:ok, msg}")

      assert %{
               type: [:Tuple],
               elements: [
                 %{body: "ok", kind: :value, type: [:Atom]},
                 %{body: "msg", kind: :variable, type: [:Variable]}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "string value" do
      {:ok, ast} = Code.string_to_quoted("\"foo\"")

      assert %{
               body: "foo",
               kind: :value,
               type: [:Binary]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "raw string" do
      {:ok, ast} = Code.string_to_quoted("<<1,2,3>>")

      assert %{
               type: [:Bitstring],
               bits: [
                 %{type: [:Integer], body: "1", kind: :value},
                 %{type: [:Integer], body: "2", kind: :value},
                 %{type: [:Integer], body: "3", kind: :value}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "tuple value" do
      {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

      assert %{
               type: [:Tuple],
               elements: [
                 %{body: "ok", kind: :value, type: [:Atom]},
                 %{body: "13", kind: :value, type: [:Integer]}
               ]
             } == Parser.parse(ast, [[:Foo, :Bar]])
    end

    test "value list with pipe" do
      {:ok, ast} = Code.string_to_quoted("[head | tail]")

      assert [
               %{
                 values: [
                   %{type: [:Variable], body: "head", kind: :variable},
                   %{type: [:Variable], body: "tail", kind: :variable}
                 ],
                 body: "|",
                 kind: :pipe
               }
             ] == Parser.parse(ast, [])
    end
  end

  describe "expandind modules via aliases" do
    test "nothing to expand" do
      module = [:Foo]
      aliases = []
      assert [:Foo] == Parser.expand_module(module, aliases)
    end

    test "aliases not match" do
      module = [:Foo, :Bar]
      aliases = [[:Bar, :Baz]]
      assert [:Bar] == Parser.expand_module(module, aliases)
    end

    test "aliases match and module expanded" do
      module = [:Bar, :Baz]
      aliases = [[:Foo, :Bar]]
      assert [:Foo, :Bar, :Baz] == Parser.expand_module(module, aliases)
    end
  end
end
