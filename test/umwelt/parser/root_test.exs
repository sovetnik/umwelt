defmodule Umwelt.Parser.RootTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Root

  describe "expandind path to the root module" do
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
                 guards: [],
                 functions: [],
                 kind: :root
               },
               [
                 %{
                   body: "Bar",
                   kind: :space,
                   note: "Foobar description",
                   context: [:Foo, :Bar],
                   attrs: [
                     %{
                       value: [%{type: [:Atom], body: "bar", kind: :literal}],
                       body: "foo",
                       kind: :attr
                     }
                   ],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                       body: "foo",
                       kind: :call,
                       note: "bar -> baz"
                     }
                   ]
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :space,
                     note: "Baz description",
                     context: [:Foo, :Bar, :Baz],
                     attrs: [],
                     guards: [],
                     functions: [
                       %{
                         arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
                         impl: %{type: [:Boolean], body: "true", kind: :literal},
                         body: "bar",
                         kind: :call
                       }
                     ]
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
                 context: [:Root],
                 attrs: [],
                 guards: [],
                 body: "Root",
                 kind: :root,
                 note: "Root description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                       body: "foo",
                       kind: :call
                     }
                   ],
                   context: [:Root, :Foo],
                   attrs: [],
                   guards: [],
                   body: "Foo",
                   kind: :space,
                   note: "Foo description"
                 },
                 [
                   %{
                     functions: [
                       %{
                         arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
                         body: "bar",
                         kind: :call
                       }
                     ],
                     context: [:Root, :Foo, :Bar],
                     attrs: [],
                     guards: [],
                     body: "Bar",
                     kind: :space,
                     note: "Bar description"
                   }
                 ],
                 [
                   %{
                     functions: [
                       %{
                         arguments: [%{type: [:Variable], body: "foo", kind: :variable}],
                         body: "baz",
                         kind: :call
                       }
                     ],
                     context: [:Root, :Foo, :Baz],
                     attrs: [],
                     guards: [],
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
               %{
                 body: "Foo",
                 kind: :root,
                 context: [:Foo],
                 attrs: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :space,
                     context: [:Foo, :Bar, :Baz],
                     attrs: [],
                     guards: [],
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
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar],
                   body: "Bar",
                   kind: :space,
                   attrs: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     context: [:Foo, :Bar, :Baz],
                     body: "Baz",
                     kind: :space,
                     attrs: [],
                     guards: [],
                     functions: []
                   }
                 ]
               ]
             ] == Root.parse(ast)
    end

    test "empty inner module expands aliases deeply" do
      {:ok, ast} =
        """
          defmodule Foo.Bar.Baz do
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 context: [:Foo],
                 body: "Foo",
                 kind: :root,
                 attrs: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar],
                   body: "Bar",
                   kind: :space,
                   attrs: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     context: [:Foo, :Bar, :Baz],
                     body: "Baz",
                     kind: :space,
                     attrs: [],
                     guards: [],
                     functions: []
                   }
                 ]
               ]
             ] == Root.parse(ast)
    end
  end

  describe "root inner nodes" do
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
                 guards: [],
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
                   guards: [],
                   fields: [
                     %{
                       elements: [
                         %{body: "foo", kind: :literal, type: [:Atom]},
                         %{body: "", kind: :literal, type: [:Atom]}
                       ],
                       type: [:Tuple]
                     },
                     %{
                       elements: [
                         %{body: "tree", kind: :literal, type: [:Atom]},
                         %{
                           context: [],
                           keyword: [],
                           type: [:Map]
                         }
                       ],
                       type: [:Tuple]
                     }
                   ],
                   functions: [
                     %{
                       arguments: [%{body: "bar", kind: :variable, type: [:Variable]}],
                       body: "foo",
                       kind: :call
                     },
                     %{
                       arguments: [%{type: [:Variable], body: "baz", kind: :variable}],
                       body: "bar",
                       kind: :call
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
                 guards: [],
                 functions: [],
                 kind: :root
               },
               [
                 %{
                   body: "Bar",
                   kind: :space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "bar", kind: :variable}],
                       body: "foo",
                       kind: :call
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
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :space,
                   context: [:Foo, :Bar],
                   note: "Foobar description",
                   attrs: [],
                   guards: [],
                   functions: []
                 }
               ]
             ] == Root.parse(ast)
    end
  end
end
