defmodule Umwelt.ParserTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser

  setup do
    code = """
    defmodule Foo.Bar do
      @moduledoc "Calculator"
      alias Foo.Jazz
      def div(a, b) do
        a / b
      end

      @doc "summarize two nums"
      def sum(%Jazz.Band{} = jazz) do
        jazz.a + jazz.b
      end
      defmodule Baz do
        @moduledoc "Special"
        def percent(a, b) do
          a / b
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
                {:__aliases__, [line: 1], [:Foo, :Bar]},
                [
                  do: {
                    :__block__,
                    [],
                    [
                      {:@, [line: 2], [{:moduledoc, [line: 2], ["Calculator"]}]},
                      {:alias, [line: 3], [{:__aliases__, [line: 3], [:Foo, :Jazz]}]},
                      {:def, [line: 4],
                       [
                         {:div, [line: 4], [{:a, [line: 4], nil}, {:b, [line: 4], nil}]},
                         [
                           do:
                             {:/, [line: 5],
                              [
                                {:a, [line: 5], nil},
                                {:b, [line: 5], nil}
                              ]}
                         ]
                       ]},
                      {:@, [line: 8], [{:doc, [line: 8], ["summarize two nums"]}]},
                      {:def, [line: 9],
                       [
                         {:sum, [line: 9],
                          [
                            {:=, [line: 9],
                             [
                               {:%, [line: 9],
                                [{:__aliases__, [line: 9], [:Jazz, :Band]}, {:%{}, [line: 9], []}]},
                               {:jazz, [line: 9], nil}
                             ]}
                          ]},
                         [
                           do:
                             {:+, [line: 10],
                              [
                                {{:., [line: 10], [{:jazz, [line: 10], nil}, :a]},
                                 [no_parens: true, line: 10], []},
                                {{:., [line: 10], [{:jazz, [line: 10], nil}, :b]},
                                 [no_parens: true, line: 10], []}
                              ]}
                         ]
                       ]},
                      {:defmodule, [line: 12],
                       [
                         {:__aliases__, [line: 12], [:Baz]},
                         [
                           do:
                             {:__block__, [],
                              [
                                {:@, [line: 13],
                                 [
                                   {:moduledoc, [line: 13], ["Special"]}
                                 ]},
                                {:def, [line: 14],
                                 [
                                   {:percent, [line: 14],
                                    [
                                      {:a, [line: 14], nil},
                                      {:b, [line: 14], nil}
                                    ]},
                                   [
                                     do:
                                       {:/, [line: 15],
                                        [
                                          {:a, [line: 15], nil},
                                          {:b, [line: 15], nil}
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

  test "parse", %{code: code} do
    assert %{
             [:Foo, :Bar] => [
               %{
                 args: [%{body: "jazz", match: [:Foo, :Jazz, :Band]}],
                 doc: ["summarize two nums"],
                 method: :sum
               },
               %{
                 args: [%{body: "a", kind: [:Undefined]}, %{body: "b", kind: [:Undefined]}],
                 method: :div
               },
               %{context: [:Foo, :Bar], moduledoc: ["Calculator"]}
             ],
             [:Foo, :Bar, :Baz] => [
               %{
                 args: [
                   %{body: "a", kind: [:Undefined]},
                   %{body: "b", kind: [:Undefined]}
                 ],
                 method: :percent
               },
               %{context: [:Foo, :Bar, :Baz], moduledoc: ["Special"]}
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
               %{body: "msg", kind: [:Undefined]}
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
