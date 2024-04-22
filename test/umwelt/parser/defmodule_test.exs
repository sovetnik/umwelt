defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

  describe "import, use and require" do
    test "import in defmodule" do
      {:ok, ast} =
        ~S"""
        defmodule Math do
        import List, only: [duplicate: 2]
          def some_function do
            duplicate(:ok, 10)
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Math",
                 context: [:Math],
                 attrs: [],
                 calls: [
                   %{
                     arguments: [
                       [:List],
                       [
                         %{
                           type: [:Tuple],
                           kind: :Value,
                           elements: [
                             %{type: [:Atom], body: "only", kind: :Value},
                             [
                               %{
                                 type: [:Tuple],
                                 kind: :Value,
                                 elements: [
                                   %{type: [:Atom], body: "duplicate", kind: :Value},
                                   %{type: [:Integer], body: "2", kind: :Value}
                                 ]
                               }
                             ]
                           ]
                         }
                       ]
                     ],
                     body: "import",
                     kind: :Call
                   }
                 ],
                 functions: [
                   %{arguments: [], body: "some_function", kind: :Function}
                 ],
                 guards: [],
                 kind: :Concept
               }
             ] == Defmodule.parse(ast, [])
    end

    test "import in def skipped as bad design" do
      {:ok, ast} =
        ~S"""
        defmodule Math do
          def some_function do
            import List, only: [duplicate: 2]
            duplicate(:ok, 10)
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Math",
                 context: [:Math],
                 attrs: [],
                 calls: [],
                 functions: [%{arguments: [], body: "some_function", kind: :Function}],
                 guards: [],
                 kind: :Concept
               }
             ] == Defmodule.parse(ast, [])
    end

    test "just one use" do
      {:ok, ast} =
        ~S"""
        defmodule Cryptoid.Mailer do
          use Swoosh.Mailer, otp_app: :cryptoid
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Mailer",
                 calls: [
                   %{
                     arguments: [
                       [:Swoosh, :Mailer],
                       [
                         %{
                           type: [:Tuple],
                           kind: :Value,
                           elements: [
                             %{type: [:Atom], body: "otp_app", kind: :Value},
                             %{type: [:Atom], body: "cryptoid", kind: :Value}
                           ]
                         }
                       ]
                     ],
                     body: "use",
                     kind: :Call
                   }
                 ],
                 context: [:Cryptoid, :Mailer],
                 functions: [],
                 guards: [],
                 kind: :Concept
               }
             ] == Defmodule.parse(ast, [])
    end

    test "use in def skipped as bad design" do
      {:ok, ast} =
        ~S"""
        defmodule Example do
          @moduledoc "use the feature"
          use Feature, option: :value
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Example",
                 calls: [
                   %{
                     arguments: [
                       [:Feature],
                       [
                         %{
                           elements: [
                             %{body: "option", kind: :Value, type: [:Atom]},
                             %{body: "value", kind: :Value, type: [:Atom]}
                           ],
                           kind: :Value,
                           type: [:Tuple]
                         }
                       ]
                     ],
                     body: "use",
                     kind: :Call
                   }
                 ],
                 context: [:Example],
                 functions: [],
                 guards: [],
                 kind: :Concept,
                 note: "use the feature"
               }
             ] == Defmodule.parse(ast, [])
    end

    test "require in defmodule" do
      {:ok, ast} =
        ~S"""
        defmodule Example do
          require Feature
          Feature.__using__(option: :value)
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Example",
                 calls: [
                   %{
                     arguments: [
                       [
                         %{
                           type: [:Tuple],
                           kind: :Value,
                           elements: [
                             %{type: [:Atom], body: "option", kind: :Value},
                             %{type: [:Atom], body: "value", kind: :Value}
                           ]
                         }
                       ]
                     ],
                     body: "__using__",
                     kind: :Call,
                     context: [:Feature]
                   },
                   %{arguments: [[:Feature]], body: "require", kind: :Call}
                 ],
                 context: [:Example],
                 functions: [],
                 guards: [],
                 kind: :Concept
               }
             ] == Defmodule.parse(ast, [])
    end
  end

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
                 body: "Bar",
                 kind: :Concept,
                 context: [:Foo, :Bar],
                 attrs: [],
                 calls: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: [:Foo, :Bar], body: "bar", kind: :Variable, keyword: []},
                       %{type: [:Foo, :Baz], body: "baz", kind: :Variable, keyword: []}
                     ],
                     body: "foobar",
                     kind: :Function
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
                 body: "Bar",
                 kind: :Concept,
                 context: [:Foo, :Bar],
                 attrs: [],
                 calls: [],
                 functions: [
                   %{
                     arguments: [
                       %{type: [:Foo, :Bar], body: "bar", kind: :Variable, keyword: []},
                       %{type: [:Foo, :Baz], body: "baz", kind: :Variable, keyword: []}
                     ],
                     body: "foobar",
                     kind: :Function
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
                 body: "Bar",
                 kind: :Concept,
                 context: [:Foo, :Bar],
                 attrs: [],
                 calls: [],
                 functions: [],
                 guards: [
                   %{
                     body: "when",
                     kind: :Operator,
                     left: %{
                       arguments: [%{type: [:Anything], body: "term", kind: :Variable}],
                       body: "is_foobar",
                       kind: :Call
                     },
                     right: %{
                       body: "membership",
                       kind: :Operator,
                       left: %{type: [:Anything], body: "term", kind: :Variable},
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
                 kind: :Concept,
                 context: [:Foo, :Bar],
                 functions: [
                   %{
                     body: "when",
                     kind: :Operator,
                     left: %{
                       arguments: [%{type: [:Anything], body: "term", kind: :Variable}],
                       body: "foobar",
                       kind: :Call
                     },
                     right: %{
                       arguments: [%{type: [:Anything], body: "term", kind: :Variable}],
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
                       arguments: [%{type: [:Anything], body: "term", kind: :Variable}],
                       body: "is_foobar",
                       kind: :Call
                     },
                     right: %{
                       body: "membership",
                       kind: :Operator,
                       left: %{type: [:Anything], body: "term", kind: :Variable},
                       right: [
                         %{type: [:Atom], body: "foo", kind: :Value},
                         %{type: [:Atom], body: "bar", kind: :Value}
                       ]
                     }
                   }
                 ],
                 attrs: [],
                 calls: []
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
                 calls: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [
                       %{body: "income", kind: :Variable, type: [:Anything]},
                       %{
                         body: "outcome",
                         default: %{type: [:List]},
                         kind: :Variable,
                         type: [:Anything]
                       }
                     ],
                     body: "reverse",
                     kind: :Function
                   },
                   %{
                     arguments: [
                       %{type: [:List], kind: :Value, body: "_"},
                       %{body: "outcome", kind: :Variable, type: [:Anything]}
                     ],
                     body: "reverse",
                     kind: :Function
                   },
                   %{
                     arguments: [
                       %{
                         body: "_",
                         head: %{body: "h", kind: :Variable, type: [:Anything]},
                         kind: :Value,
                         tail: %{type: [:Anything], body: "t", kind: :Variable},
                         type: [:List]
                       },
                       %{type: [:Anything], body: "outcome", kind: :Variable}
                     ],
                     body: "reverse",
                     kind: :Function
                   }
                 ],
                 kind: :Concept
               }
             ] == Defmodule.parse(ast, [])
    end

    test "just a module with defstruct" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
            defstruct foo: nil, tree: %{}
          end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 body: "Bar",
                 kind: :Concept,
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
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "module with defstruct and functions" do
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
                 kind: :Concept,
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
                 kind: :Concept,
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
                 kind: :Concept,
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
                 calls: [],
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
                 kind: :Concept,
                 note: "Foobar description",
                 attrs: [],
                 calls: [],
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
                 kind: :Concept,
                 attrs: [],
                 calls: [],
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
                 calls: [],
                 guards: [],
                 functions: [
                   %{
                     arguments: [
                       %{
                         body: "bar",
                         kind: :Variable,
                         type: [:Anything]
                       }
                     ],
                     body: "foo",
                     kind: :Function,
                     note: "bar -> baz"
                   }
                 ],
                 kind: :Concept,
                 note: "Foobar description"
               },
               [
                 %{
                   body: "Baz",
                   context: [:Foo, :Bar, :Baz],
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: [
                     %{
                       arguments: [%{body: "baz", kind: :Variable, type: [:Anything]}],
                       body: "bar",
                       impl: %{body: "true", kind: :Value, type: [:Boolean]},
                       kind: :Function
                     }
                   ],
                   kind: :Concept,
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
                 kind: :Concept,
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
                   kind: :Concept,
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
                     kind: :Concept,
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
                     kind: :Concept,
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
                 kind: :Concept,
                 context: [:Foo],
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   body: "Bar",
                   kind: :Concept,
                   context: [:Foo, :Bar],
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :Concept,
                     attrs: [],
                     calls: [],
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
                 kind: :Concept,
                 attrs: [],
                 calls: [],
                 guards: [],
                 functions: []
               },
               [
                 %{
                   context: [:Foo, :Bar, :Baz],
                   body: "Baz",
                   kind: :Concept,
                   attrs: [],
                   calls: [],
                   guards: [],
                   functions: []
                 }
               ]
             ] == Defmodule.parse(ast, [])
    end
  end
end
