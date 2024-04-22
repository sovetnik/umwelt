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
                 calls: [],
                 guards: [],
                 functions: [],
                 kind: :Root
               },
               [
                 %{
                   body: "Bar",
                   kind: :Space,
                   note: "Foobar description",
                   context: [:Foo, :Bar],
                   attrs: [
                     %{
                       value: %{type: [:Atom], body: "bar", kind: :Value},
                       body: "foo",
                       kind: :Attr
                     }
                   ],
                   calls: [],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{type: [:Anything], body: "bar", kind: :Variable}],
                       body: "foo",
                       kind: :Function,
                       note: "bar -> baz"
                     }
                   ]
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :Space,
                     note: "Baz description",
                     context: [:Foo, :Bar, :Baz],
                     attrs: [],
                     calls: [],
                     guards: [],
                     functions: [
                       %{
                         arguments: [%{type: [:Anything], body: "baz", kind: :Variable}],
                         impl: %{type: [:Boolean], body: "true", kind: :Value},
                         body: "bar",
                         kind: :Function
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
                     arguments: [%{type: [:Anything], body: "once", kind: :Variable}],
                     body: "root_one",
                     kind: :Function
                   },
                   %{
                     arguments: [%{type: [:Anything], body: "twice", kind: :Variable}],
                     body: "root_two",
                     kind: :Function
                   }
                 ],
                 context: [:Root],
                 attrs: [],
                 calls: [],
                 guards: [],
                 body: "Root",
                 kind: :Root,
                 note: "Root description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Anything], body: "bar", kind: :Variable}],
                       body: "foo",
                       kind: :Function
                     }
                   ],
                   context: [:Root, :Foo],
                   attrs: [],
                   calls: [],
                   guards: [],
                   body: "Foo",
                   kind: :Space,
                   note: "Foo description"
                 },
                 [
                   %{
                     functions: [
                       %{
                         arguments: [%{type: [:Anything], body: "baz", kind: :Variable}],
                         body: "bar",
                         kind: :Function
                       }
                     ],
                     context: [:Root, :Foo, :Bar],
                     attrs: [],
                     calls: [],
                     guards: [],
                     body: "Bar",
                     kind: :Space,
                     note: "Bar description"
                   }
                 ],
                 [
                   %{
                     functions: [
                       %{
                         arguments: [%{type: [:Anything], body: "foo", kind: :Variable}],
                         body: "baz",
                         kind: :Function
                       }
                     ],
                     context: [:Root, :Foo, :Baz],
                     attrs: [],
                     calls: [],
                     guards: [],
                     body: "Baz",
                     kind: :Space,
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
                 kind: :Root,
                 context: [:Foo],
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :Space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :Space,
                     context: [:Foo, :Bar, :Baz],
                     attrs: [],
                     calls: [],
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
                 kind: :Root,
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar],
                   body: "Bar",
                   kind: :Space,
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     context: [:Foo, :Bar, :Baz],
                     body: "Baz",
                     kind: :Space,
                     attrs: [],
                     calls: [],
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
                 kind: :Root,
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar],
                   body: "Bar",
                   kind: :Space,
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     context: [:Foo, :Bar, :Baz],
                     body: "Baz",
                     kind: :Space,
                     attrs: [],
                     calls: [],
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
                 calls: [],
                 guards: [],
                 functions: [],
                 kind: :Root
               },
               [
                 %{
                   body: "Bar",
                   note: "Foobar description",
                   kind: :Space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   calls: [],
                   guards: [],
                   fields: [
                     %{
                       kind: :Field,
                       type: [:Anything],
                       body: "foo",
                       value: %{type: [:Atom], body: "nil", kind: :Value}
                     },
                     %{
                       kind: :Field,
                       type: [:Anything],
                       body: "tree",
                       value: %{type: [:Map], kind: :Value, keyword: []}
                     }
                   ],
                   functions: [
                     %{
                       arguments: [%{body: "bar", kind: :Variable, type: [:Anything]}],
                       body: "foo",
                       kind: :Function
                     },
                     %{
                       arguments: [%{type: [:Anything], body: "baz", kind: :Variable}],
                       body: "bar",
                       kind: :Function
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
                 calls: [],
                 guards: [],
                 functions: [],
                 kind: :Root
               },
               [
                 %{
                   body: "Bar",
                   kind: :Space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{type: [:Anything], body: "bar", kind: :Variable}],
                       body: "foo",
                       kind: :Function
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
                 kind: :Root,
                 context: [:Foo],
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :Space,
                   context: [:Foo, :Bar],
                   note: "Foobar description",
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 }
               ]
             ] == Root.parse(ast)
    end
  end
end
