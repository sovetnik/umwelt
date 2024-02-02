defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

  describe "module children" do
    test "module with defguard only" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            defguard is_foobar(term) when term in [:foo, :bar]
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Bar",
                 kind: :space,
                 context: [:Foo, :Bar],
                 functions: [],
                 guards: [
                   %{
                     body: "when",
                     kind: :operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :literal}],
                       body: "is_foobar",
                       kind: :call
                     },
                     right: %{
                       body: "membership",
                       kind: :comparison,
                       left: %{type: [:Variable], body: "term", kind: :literal},
                       right: [
                         %{type: [:Atom], body: "foo", kind: :literal},
                         %{type: [:Atom], body: "bar", kind: :literal}
                       ]
                     }
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
    end

    test "module with defguard" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            defguard is_foobar(term) when term in [:foo, :bar]
            def foobar(term) when is_foobar(term) do
              term <> term
            end
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Bar",
                 kind: :space,
                 context: [:Foo, :Bar],
                 functions: [
                   %{
                     body: "when",
                     kind: :operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :literal}],
                       body: "foobar",
                       kind: :call
                     },
                     right: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :literal}],
                       body: "is_foobar",
                       kind: :call
                     }
                   }
                 ],
                 guards: [
                   %{
                     body: "when",
                     kind: :operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :literal}],
                       body: "is_foobar",
                       kind: :call
                     },
                     right: %{
                       body: "membership",
                       kind: :comparison,
                       left: %{type: [:Variable], body: "term", kind: :literal},
                       right: [
                         %{type: [:Atom], body: "foo", kind: :literal},
                         %{type: [:Atom], body: "bar", kind: :literal}
                       ]
                     }
                   }
                 ],
                 attrs: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "module with multiple clauses function" do
      {:ok, ast} =
        ~S"""
          defmodule Enumeric do
            def reverse(income, outcome \\ [])
            def reverse([], outcome), do: outcome
            def reverse([h | t], outcome), do: reverse(t, [h | outcome])
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Enumeric",
                 context: [:Enumeric],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [
                       %{body: "income", kind: :literal, type: [:Variable]},
                       %{
                         default_arg: %{
                           arg: %{type: [:Variable], body: "outcome", kind: :literal},
                           default_value: []
                         }
                       }
                     ],
                     body: "reverse",
                     kind: :call
                   },
                   %{
                     arguments: [[], %{body: "outcome", kind: :literal, type: [:Variable]}],
                     body: "reverse",
                     kind: :call
                   },
                   %{
                     arguments: [
                       [
                         %{
                           body: "|",
                           kind: :pipe,
                           values: [
                             %{body: "h", kind: :literal, type: [:Variable]},
                             %{body: "t", kind: :literal, type: [:Variable]}
                           ]
                         }
                       ],
                       %{body: "outcome", kind: :literal, type: [:Variable]}
                     ],
                     body: "reverse",
                     kind: :call
                   }
                 ],
                 kind: :space
               }
             ] == Defmodule.parse(ast, [])
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
                     body: :tuple,
                     kind: :structure
                   },
                   %{
                     elements: [
                       %{body: "tree", kind: :literal, type: [:Atom]},
                       %{body: :map, context: [], keyword: [], kind: :structure}
                     ],
                     body: :tuple,
                     kind: :structure
                   }
                 ],
                 functions: [
                   %{
                     arguments: [%{body: "bar", kind: :literal, type: [:Variable]}],
                     body: "foo",
                     kind: :call
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
                     body: "bar",
                     kind: :call
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
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
                 body: "Bar",
                 kind: :space,
                 context: [:Foo, :Bar],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                     body: "foo",
                     kind: :call
                   }
                 ],
                 note: "Foobar description"
               }
             ] == Defmodule.parse(ast, [])
    end

    test "just a module with module attribute" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
            @fizbuzz {:fizz, :buzz}
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 context: [:Foo, :Bar],
                 body: "Bar",
                 kind: :space,
                 attrs: [
                   %{
                     body: "fizbuzz",
                     kind: :attr,
                     value: [
                       %{
                         elements: [
                           %{body: "fizz", kind: :literal, type: [:Atom]},
                           %{body: "buzz", kind: :literal, type: [:Atom]}
                         ],
                         body: :tuple,
                         kind: :structure
                       }
                     ]
                   }
                 ],
                 guards: [],
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
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
                 context: [:Foo, :Bar],
                 body: "Bar",
                 kind: :space,
                 note: "Foobar description",
                 attrs: [],
                 guards: [],
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "empty module" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 context: [:Foo, :Bar],
                 body: "Bar",
                 kind: :space,
                 attrs: [],
                 guards: [],
                 functions: []
               }
             ] ==
               Defmodule.parse(ast, [])
    end
  end

  describe "expanding aliases" do
    test "inner module expands aliases" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
            @moduledoc "Foobar description"
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
                 body: "Bar",
                 context: [:Foo, :Bar],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{body: "bar", kind: :literal, type: [:Variable]}],
                     body: "foo",
                     kind: :call,
                     note: "bar -> baz"
                   }
                 ],
                 kind: :space,
                 note: "Foobar description"
               },
               [
                 %{
                   body: "Baz",
                   context: [:Foo, :Bar, :Baz],
                   attrs: [],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{body: "baz", kind: :literal, type: [:Variable]}],
                       body: "bar",
                       impl: %{body: "true", kind: :literal, type: [:Boolean]},
                       kind: :call
                     }
                   ],
                   kind: :space,
                   note: "Baz description"
                 }
               ]
             ] == Defmodule.parse(ast, [])
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
                     kind: :call
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "twice", kind: :literal}],
                     body: "root_two",
                     kind: :call
                   }
                 ],
                 context: [:Root],
                 attrs: [],
                 guards: [],
                 body: "Root",
                 kind: :space,
                 note: "Root description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
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
                         arguments: [%{type: [:Variable], body: "baz", kind: :literal}],
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
                         arguments: [%{type: [:Variable], body: "foo", kind: :literal}],
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
             ] == Defmodule.parse(ast, [])
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
                 kind: :space,
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
                     attrs: [],
                     guards: [],
                     context: [:Foo, :Bar, :Baz],
                     functions: []
                   }
                 ]
               ]
             ] == Defmodule.parse(ast, [])
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
             ] == Defmodule.parse(ast, [])
    end
  end
end
