defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

  describe "module children" do
    test "module with aliased argument in function" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            alias Foo.Bar
            alias Foo.Baz
            def foobar(%Bar{} = bar, %Baz{} = baz) do
            end
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Bar",
                 kind: :Space,
                 context: [:Foo, :Bar],
                 functions: [
                   %{
                     arguments: [
                       %{type: [:Foo, :Bar], body: "bar", kind: :Variable, keyword: []},
                       %{type: [:Foo, :Baz], body: "baz", kind: :Variable, keyword: []}
                     ],
                     body: "foobar",
                     kind: :Call
                   }
                 ],
                 guards: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "module with combined aliases of argument in function" do
      {:ok, ast} =
        ~S"""
          defmodule Foo.Bar do
            alias Foo.{ Bar, Baz }
            def foobar(%Bar{} = bar, %Baz{} = baz) do
            end
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Bar",
                 kind: :Space,
                 context: [:Foo, :Bar],
                 functions: [
                   %{
                     arguments: [
                       %{type: [:Foo, :Bar], body: "bar", kind: :Variable, keyword: []},
                       %{type: [:Foo, :Baz], body: "baz", kind: :Variable, keyword: []}
                     ],
                     body: "foobar",
                     kind: :Call
                   }
                 ],
                 guards: []
               }
             ] == Defmodule.parse(ast, [])
    end

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
                 kind: :Space,
                 context: [:Foo, :Bar],
                 functions: [],
                 guards: [
                   %{
                     body: "when",
                     kind: :Operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :Variable}],
                       body: "is_foobar",
                       kind: :Call
                     },
                     right: %{
                       body: "membership",
                       kind: :Operator,
                       left: %{type: [:Variable], body: "term", kind: :Variable},
                       right: [
                         %{type: [:Atom], body: "foo", kind: :Value},
                         %{type: [:Atom], body: "bar", kind: :Value}
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
                 kind: :Space,
                 context: [:Foo, :Bar],
                 functions: [
                   %{
                     body: "when",
                     kind: :Operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :Variable}],
                       body: "foobar",
                       kind: :Call
                     },
                     right: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :Variable}],
                       body: "is_foobar",
                       kind: :Call
                     }
                   }
                 ],
                 guards: [
                   %{
                     body: "when",
                     kind: :Operator,
                     left: %{
                       arguments: [%{type: [:Variable], body: "term", kind: :Variable}],
                       body: "is_foobar",
                       kind: :Call
                     },
                     right: %{
                       body: "membership",
                       kind: :Operator,
                       left: %{type: [:Variable], body: "term", kind: :Variable},
                       right: [
                         %{type: [:Atom], body: "foo", kind: :Value},
                         %{type: [:Atom], body: "bar", kind: :Value}
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
                       %{body: "income", kind: :Variable, type: [:Variable]},
                       %{
                         body: "outcome",
                         default: %{type: [:List]},
                         kind: :Variable,
                         type: [:Variable]
                       }
                     ],
                     body: "reverse",
                     kind: :Call
                   },
                   %{
                     arguments: [
                       %{type: [:List], kind: :Value, body: "_"},
                       %{body: "outcome", kind: :Variable, type: [:Variable]}
                     ],
                     body: "reverse",
                     kind: :Call
                   },
                   %{
                     arguments: [
                       %{
                         body: "_",
                         head: %{body: "h", kind: :Variable, type: [:Variable]},
                         kind: :Value,
                         tail: %{type: [:Variable], body: "t", kind: :Variable},
                         type: [:List]
                       },
                       %{type: [:Variable], body: "outcome", kind: :Variable}
                     ],
                     body: "reverse",
                     kind: :Call
                   }
                 ],
                 kind: :Space
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
                 kind: :Space,
                 context: [:Foo, :Bar],
                 attrs: [],
                 guards: [],
                 fields: [
                   %{
                     kind: :Field,
                     type: [:Variable],
                     body: "foo",
                     value: %{type: [:Atom], body: "nil", kind: :Value}
                   },
                   %{
                     kind: :Field,
                     type: [:Variable],
                     body: "tree",
                     value: %{type: [:Map], kind: :Value, keyword: []}
                   }
                 ],
                 functions: [
                   %{
                     arguments: [%{body: "bar", kind: :Variable, type: [:Variable]}],
                     body: "foo",
                     kind: :Call
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "baz", kind: :Variable}],
                     body: "bar",
                     kind: :Call
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
                 kind: :Space,
                 context: [:Foo, :Bar],
                 attrs: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [%{type: [:Variable], body: "bar", kind: :Variable}],
                     body: "foo",
                     kind: :Call
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
                 kind: :Space,
                 attrs: [
                   %{
                     body: "fizbuzz",
                     kind: :Attr,
                     value: %{
                       elements: [
                         %{body: "fizz", kind: :Value, type: [:Atom]},
                         %{body: "buzz", kind: :Value, type: [:Atom]}
                       ],
                       kind: :Value,
                       type: [:Tuple]
                     }
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
                 kind: :Space,
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
                 kind: :Space,
                 attrs: [],
                 guards: [],
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
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
                     arguments: [
                       %{
                         body: "bar",
                         kind: :Variable,
                         type: [:Variable]
                       }
                     ],
                     body: "foo",
                     kind: :Call,
                     note: "bar -> baz"
                   }
                 ],
                 kind: :Space,
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
                       arguments: [%{body: "baz", kind: :Variable, type: [:Variable]}],
                       body: "bar",
                       impl: %{body: "true", kind: :Value, type: [:Boolean]},
                       kind: :Call
                     }
                   ],
                   kind: :Space,
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
                     arguments: [%{type: [:Variable], body: "once", kind: :Variable}],
                     body: "root_one",
                     kind: :Call
                   },
                   %{
                     arguments: [%{type: [:Variable], body: "twice", kind: :Variable}],
                     body: "root_two",
                     kind: :Call
                   }
                 ],
                 context: [:Root],
                 attrs: [],
                 guards: [],
                 body: "Root",
                 kind: :Space,
                 note: "Root description"
               },
               [
                 %{
                   functions: [
                     %{
                       arguments: [%{type: [:Variable], body: "bar", kind: :Variable}],
                       body: "foo",
                       kind: :Call
                     }
                   ],
                   context: [:Root, :Foo],
                   attrs: [],
                   guards: [],
                   body: "Foo",
                   kind: :Space,
                   note: "Foo description"
                 },
                 [
                   %{
                     functions: [
                       %{
                         arguments: [%{type: [:Variable], body: "baz", kind: :Variable}],
                         body: "bar",
                         kind: :Call
                       }
                     ],
                     context: [:Root, :Foo, :Bar],
                     attrs: [],
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
                         arguments: [%{type: [:Variable], body: "foo", kind: :Variable}],
                         body: "baz",
                         kind: :Call
                       }
                     ],
                     context: [:Root, :Foo, :Baz],
                     attrs: [],
                     guards: [],
                     body: "Baz",
                     kind: :Space,
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
                 kind: :Space,
                 context: [:Foo],
                 attrs: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :Space,
                   context: [:Foo, :Bar],
                   attrs: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :Space,
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
                 kind: :Space,
                 attrs: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar, :Baz],
                   body: "Baz",
                   kind: :Space,
                   attrs: [],
                   guards: [],
                   functions: []
                 }
               ]
             ] == Defmodule.parse(ast, [])
    end
  end
end
