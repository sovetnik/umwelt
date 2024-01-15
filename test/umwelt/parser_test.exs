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
             [:Root] => [
               %{args: [%{body: "twice", kind: [:Capture]}], function: :root_two},
               %{args: [%{body: "once", kind: [:Capture]}], function: :root_one},
               %{context: [:Root], moduledoc: ["Foo description"]}
             ],
             [:Root, :Foo] => [
               %{args: [%{body: "bar", kind: [:Capture]}], function: :foo},
               %{context: [:Root, :Foo], moduledoc: ["Foo description"]}
             ],
             [:Root, :Foo, :Bar] => [
               %{args: [%{body: "baz", kind: [:Capture]}], function: :bar},
               %{context: [:Root, :Foo, :Bar], moduledoc: ["Bar description"]}
             ],
             [:Root, :Foo, :Baz] => [
               %{args: [%{body: "foo", kind: [:Capture]}], function: :baz},
               %{context: [:Root, :Foo, :Baz], moduledoc: ["Baz description"]}
             ]
           } ==
             {:ok, code}
             |> Parser.read_ast()
             |> Parser.parse()
  end

  test "tuple pair" do
    {:ok, ast} = Code.string_to_quoted("{:ok, msg}")

    assert %{
             tuple: [
               %{body: "ok", kind: [:Atom]},
               %{body: "msg", kind: [:Capture]}
             ]
           } ==
             Parser.parse(ast, [[:Foo, :Bar]])
  end

  test "tuple literal" do
    {:ok, ast} = Code.string_to_quoted("{:ok, 13}")

    assert %{
             tuple: [
               %{body: "ok", kind: [:Atom]},
               %{body: "13", kind: [:Integer]}
             ]
           } ==
             Parser.parse(ast, [[:Foo, :Bar]])
  end
end
