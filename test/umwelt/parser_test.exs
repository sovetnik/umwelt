defmodule Umwelt.ParserTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser

  setup do
    code = """
        defmodule Root do
          @moduledoc "Foo description"
          def root_one(once) do
            1
          end
          def root_two(twice) do
            2
          end
          defmodule Foo do
            @moduledoc "Foo description"
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

  test "read_ast when error" do
    assert {:error, "read failed"} ==
             Parser.read_ast({:error, "read failed"})
  end

  test "read_ast", %{code: code} do
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
                      {:@, [line: 2], [{:moduledoc, [line: 2], ["Foo description"]}]},
                      {:def, [line: 3],
                       [{:root_one, [line: 3], [{:once, [line: 3], nil}]}, [do: 1]]},
                      {:def, [line: 6],
                       [{:root_two, [line: 6], [{:twice, [line: 6], nil}]}, [do: 2]]},
                      {
                        :defmodule,
                        [line: 9],
                        [
                          {:__aliases__, [line: 9], [:Foo]},
                          [
                            do:
                              {:__block__, [],
                               [
                                 {:@, [line: 10],
                                  [{:moduledoc, [line: 10], ["Foo description"]}]},
                                 {:def, [line: 11],
                                  [{:foo, [line: 11], [{:bar, [line: 11], nil}]}, [do: :baz]]},
                                 {:defmodule, [line: 14],
                                  [
                                    {:__aliases__, [line: 14], [:Bar]},
                                    [
                                      do:
                                        {:__block__, [],
                                         [
                                           {:@, [line: 15],
                                            [{:moduledoc, [line: 15], ["Bar description"]}]},
                                           {:def, [line: 16],
                                            [
                                              {:bar, [line: 16], [{:baz, [line: 16], nil}]},
                                              [do: :foo]
                                            ]}
                                         ]}
                                    ]
                                  ]},
                                 {:defmodule, [line: 20],
                                  [
                                    {:__aliases__, [line: 20], [:Baz]},
                                    [
                                      do:
                                        {:__block__, [],
                                         [
                                           {:@, [line: 21],
                                            [{:moduledoc, [line: 21], ["Baz description"]}]},
                                           {:def, [line: 22],
                                            [
                                              {:baz, [line: 22], [{:foo, [line: 22], nil}]},
                                              [do: :bar]
                                            ]}
                                         ]}
                                    ]
                                  ]}
                               ]}
                          ]
                        ]
                      }
                    ]
                  }
                ]
              ]
            }} == Parser.read_ast({:ok, code})
  end

  test "parse", %{code: code} do
    assert %{
             [:Root] => %{
               body: "Root",
               context: [:Root],
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "once", kind: :literal}],
                   body: "root_one",
                   kind: :function
                 },
                 %{
                   arguments: [%{type: [:Variable], body: "twice", kind: :literal}],
                   body: "root_two",
                   kind: :function
                 }
               ],
               kind: :space,
               note: "Foo description"
             },
             [:Root, :Foo] => %{
               body: "Foo",
               context: [:Root, :Foo],
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                   body: "foo",
                   kind: :function
                 }
               ],
               kind: :space,
               note: "Foo description"
             },
             [:Root, :Foo, :Bar] => %{
               body: "Bar",
               context: [:Root, :Foo, :Bar],
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                   body: "bar",
                   kind: :function
                 }
               ],
               kind: :space,
               note: "Bar description"
             },
             [:Root, :Foo, :Baz] => %{
               body: "Baz",
               context: [:Root, :Foo, :Baz],
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "foo", kind: :literal}],
                   body: "baz",
                   kind: :function
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

  test "tuple pair" do
    {:ok, ast} = Code.string_to_quoted("{:ok, msg}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "msg", kind: :literal, type: [:Variable]}
             ]
           } ==
             Parser.parse(ast, [[:Foo, :Bar]])
  end

  test "tuple literal" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             tuple: [
               %{body: "ok", kind: :literal, type: [:Atom]},
               %{body: "13", kind: :literal, type: [:Integer]}
             ]
           } ==
             Parser.parse(ast, [[:Foo, :Bar]])
  end
end
