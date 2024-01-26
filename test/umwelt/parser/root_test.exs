defmodule Umwelt.Parser.RootTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Root

  test "inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar description"
          @foo :bar
          @doc "bar -> baz"
          def foo(bar) do
            :baz
          end
          defmodule Baz do
            @moduledoc "Baz description"
            @impl true
            def bar(baz) do
              :foo
            end
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               body: "Foo",
               context: [:Foo],
               attrs: [],
               functions: [],
               kind: :root
             },
             [
               %{
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                     body: "foo",
                     kind: :function,
                     note: "bar -> baz"
                   }
                 ],
                 context: [:Foo, :Bar],
                 attrs: [
                   %{
                     value: [%{type: [:Atom], body: "bar", kind: :literal}],
                     body: "foo",
                     kind: :attr
                   }
                 ],
                 body: "Bar",
                 kind: :space,
                 note: "Foobar description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                       impl: %{type: [:Boolean], body: "true", kind: :literal},
                       body: "bar",
                       kind: :function
                     }
                   ],
                   context: [:Foo, :Bar, :Baz],
                   attrs: [],
                   body: "Baz",
                   kind: :space,
                   note: "Baz description"
                 }
               ]
             ]
           ] == Root.parse(ast)
  end

  test "deep inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Root do
          @moduledoc "Root description"
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
      |> Code.string_to_quoted()

    assert [
             %{
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
               context: [:Root],
               attrs: [],
               body: "Root",
               kind: :root,
               note: "Root description"
             },
             [
               %{
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                     body: "foo",
                     kind: :function
                   }
                 ],
                 context: [:Root, :Foo],
                 attrs: [],
                 body: "Foo",
                 kind: :space,
                 note: "Foo description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                       body: "bar",
                       kind: :function
                     }
                   ],
                   context: [:Root, :Foo, :Bar],
                   attrs: [],
                   body: "Bar",
                   kind: :space,
                   note: "Bar description"
                 }
               ],
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "foo", kind: :literal}],
                       body: "baz",
                       kind: :function
                     }
                   ],
                   context: [:Root, :Foo, :Baz],
                   attrs: [],
                   body: "Baz",
                   kind: :space,
                   note: "Baz description"
                 }
               ]
             ]
           ] == Root.parse(ast)
  end

  test "empty inner modules expands aliases" do
    {:ok, ast} =
      """
        defmodule Foo do
          defmodule Bar do
            defmodule Baz do
            end
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{body: "Foo", kind: :root, context: [:Foo], attrs: [], functions: []},
             [
               %{body: "Bar", kind: :space, context: [:Foo, :Bar], attrs: [], functions: []},
               [
                 %{
                   body: "Baz",
                   kind: :space,
                   context: [:Foo, :Bar, :Baz],
                   attrs: [],
                   functions: []
                 }
               ]
             ]
           ] == Root.parse(ast)
  end

  test "empty inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          defmodule Baz do
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               context: [:Foo],
               body: "Foo",
               kind: :root,
               attrs: [],
               functions: []
             },
             [
               %{
                 context: [:Foo, :Bar],
                 body: "Bar",
                 kind: :space,
                 attrs: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar, :Baz],
                   body: "Baz",
                   kind: :space,
                   attrs: [],
                   functions: []
                 }
               ]
             ]
           ] == Root.parse(ast)
  end

  test "just a module with defstruct" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar description"
          defstruct foo: nil, tree: %{}
          def foo(bar) do
            :baz
          end
          def bar(baz) do
            :foo
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               body: "Foo",
               context: [:Foo],
               attrs: [],
               functions: [],
               kind: :root
             },
             [
               %{
                 body: "Bar",
                 note: "Foobar description",
                 kind: :space,
                 context: [:Foo, :Bar],
                 attrs: [],
                 fields: [
                   %{
                     tuple: [
                       %{type: [:Atom], body: "foo", kind: :literal},
                       %{type: [:Atom], body: "", kind: :literal}
                     ]
                   },
                   %{tuple: [%{type: [:Atom], body: "tree", kind: :literal}, %{struct: []}]}
                 ],
                 functions: [
                   %{
                     arguments: [%{body: "bar", kind: :literal, type: [:Variable]}],
                     body: "foo",
                     kind: :function
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                     body: "bar",
                     kind: :function
                   }
                 ]
               }
             ]
           ] == Root.parse(ast)
  end

  test "just a module with function" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar description"
          def foo(bar) do
            :baz
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               body: "Foo",
               context: [:Foo],
               attrs: [],
               functions: [],
               kind: :root
             },
             [
               %{
                 body: "Bar",
                 kind: :space,
                 context: [:Foo, :Bar],
                 attrs: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                     body: "foo",
                     kind: :function
                   }
                 ],
                 note: "Foobar description"
               }
             ]
           ] == Root.parse(ast)
  end

  test "just a module with moduledoc only" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar description"
        end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               body: "Foo",
               kind: :root,
               context: [:Foo],
               attrs: [],
               functions: []
             },
             [
               %{
                 body: "Bar",
                 kind: :space,
                 context: [:Foo, :Bar],
                 note: "Foobar description",
                 attrs: [],
                 functions: []
               }
             ]
           ] == Root.parse(ast)
  end
end
