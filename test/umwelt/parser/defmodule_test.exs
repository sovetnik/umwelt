defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

  test "example from official docs" do
    {:ok, ast} =
      """
      defmodule StringHelpers do
        @typedoc "A word from the dictionary"
        @type word() :: String.t()

        @spec long_word?(word()) :: boolean()
        def long_word?(word) when is_binary(word) do
          String.length(word) > 8
        end
      end
      """
      |> Code.string_to_quoted()

    assert [
             %{
               attrs: [],
               body: "StringHelpers",
               calls: [],
               context: [:StringHelpers],
               functions: [
                 %{
                   body: "when",
                   kind: :Operator,
                   left: %{
                     arguments: [%{body: "word", kind: :Variable, type: [:Anything]}],
                     body: "long_word?",
                     kind: :Call
                   },
                   right: %{
                     arguments: [%{body: "word", kind: :Variable, type: [:Anything]}],
                     body: "is_binary",
                     kind: :Call
                   },
                   spec: %{
                     type: %{arguments: [], body: "boolean", kind: :Call},
                     arguments: [%{arguments: [], body: "word", kind: :Call}],
                     body: "long_word?",
                     kind: :Call
                   }
                 }
               ],
               guards: [],
               kind: :Concept,
               types: [
                 %{
                   type: %{context: [:String], arguments: [], body: "t", kind: :Call},
                   arguments: [],
                   body: "word",
                   kind: :Call,
                   note: "A word from the dictionary"
                 }
               ]
             }
           ] == Defmodule.parse(ast, [])
  end

  describe "parse part of itself" do
    test "module" do
      {:ok, ast} =
        """
        defmodule Umwelt.Parser.Typespec do
          @moduledoc "Parses Typespec definition AST"

          def parse([{type, _, [left, right]}], aliases, _context) do
            %{
              kind: :Typespec,
              body: to_string(type),
              type: Parser.parse(left, aliases),
              spec: Parser.parse(right, aliases)
            }
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 functions: [
                   %{
                     arguments: [
                       %{
                         type: [:List],
                         values: [
                           %{
                             type: [:Tuple],
                             kind: :Value,
                             elements: [
                               %{type: [:Anything], body: "type", kind: :Variable},
                               %{type: [:Anything], body: "_", kind: :Variable},
                               [
                                 %{type: [:Anything], body: "left", kind: :Variable},
                                 %{type: [:Anything], body: "right", kind: :Variable}
                               ]
                             ]
                           }
                         ],
                         body: "_",
                         kind: :Value
                       },
                       %{type: [:Anything], body: "aliases", kind: :Variable},
                       %{type: [:Anything], body: "_context", kind: :Variable}
                     ],
                     body: "parse",
                     kind: :Function
                   }
                 ],
                 context: [:Umwelt, :Parser, :Typespec],
                 body: "Typespec",
                 kind: :Concept,
                 guards: [],
                 types: [],
                 attrs: [],
                 calls: [],
                 note: "Parses Typespec definition AST"
               }
             ] == Defmodule.parse(ast, [])
    end
  end

  describe "types" do
    test "complex typedoc" do
      {:ok, ast} =
        ~s[
          defmodule StringHelpers do
            @moduledoc "Helpers for string"
            @typedoc ~S"""
              A word from the dictionary:
              ```
                ~w|foo bar baz|
              ```

              Type describes any word form a given dictionary

            """
            @type word() :: String.t()
          end
        ]
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "StringHelpers",
                 calls: [],
                 context: [:StringHelpers],
                 functions: [],
                 guards: [],
                 kind: :Concept,
                 types: [
                   %{
                     arguments: [],
                     body: "word",
                     kind: :Call,
                     note: "Description of type",
                     type: %{arguments: [], body: "t", context: [:String], kind: :Call}
                   }
                 ],
                 note: "Helpers for string"
               }
             ] == Defmodule.parse(ast, [])
    end
  end

  describe "@doc; @spec; def" do
    test "combo defmodule" do
      {:ok, ast} =
        ~S"""
        defmodule Calendar do
          @moduledoc "Calndar concept"
          @doc "days between past date and today"
          @spec days_since_epoch(year :: integer, month :: integer, day :: integer) :: integer
          def days_since_epoch(year, month, day) do
          # fun body
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %{
                 functions: [
                   %{
                     spec: %{
                       type: [:Integer],
                       arguments: [
                         %{type: [:Integer], body: "year", kind: :Variable},
                         %{type: [:Integer], body: "month", kind: :Variable},
                         %{type: [:Integer], body: "day", kind: :Variable}
                       ],
                       body: "days_since_epoch",
                       kind: :Call
                     },
                     arguments: [
                       %{type: [:Anything], body: "year", kind: :Variable},
                       %{type: [:Anything], body: "month", kind: :Variable},
                       %{type: [:Anything], body: "day", kind: :Variable}
                     ],
                     body: "days_since_epoch",
                     kind: :Function,
                     note: "days between past date and today"
                   }
                 ],
                 context: [:Calendar],
                 body: "Calendar",
                 kind: :Concept,
                 guards: [],
                 types: [],
                 attrs: [],
                 calls: [],
                 note: "Calndar concept"
               }
             ] == Defmodule.parse(ast, [])
    end
  end

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
                 types: [],
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
                 types: [],
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
                 types: [],
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
                 types: [],
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
                 types: [],
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
                 guards: [],
                 types: []
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
                 guards: [],
                 types: []
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
                 ],
                 types: []
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
                 calls: [],
                 types: []
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
                 types: [],
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
                 types: [],
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
                 types: [],
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
                 types: [],
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
                 types: [],
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "just a module with simple moduledoc only" do
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
                 types: [],
                 functions: []
               }
             ] == Defmodule.parse(ast, [])
    end

    test "just a module with complex moduledoc only" do
      {:ok, ast} =
        ~S[
        defmodule Formulae do
          @moduledoc ~S"""
            A set of functions to deal with analytical formulae.

            Now the formula is compiled and might be invoked by calling `Formulae.eval/2`
            passing a formula _and_ bindings. First call to `eval/2` would lazily compile
            the module if needed.

            ```elixir
            iex|2 ▶ f.eval.(a: 3, b: 4, c: 2)
            0.9968146982068622
            ```
          """
        end
  ]
        |> Code.string_to_quoted()

      assert [
               %{
                 attrs: [],
                 body: "Formulae",
                 calls: [],
                 context: [:Formulae],
                 functions: [],
                 guards: [],
                 kind: :Concept,
                 note: "Description of Formulae",
                 types: []
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
                 types: [],
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
                 types: [],
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
                   types: [],
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
                 types: [],
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
                   types: [],
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
                     types: [],
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
                     types: [],
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
                 types: [],
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
                   types: [],
                   functions: []
                 },
                 [
                   %{
                     body: "Baz",
                     kind: :Concept,
                     attrs: [],
                     calls: [],
                     guards: [],
                     types: [],
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
                 types: [],
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
                   types: [],
                   functions: []
                 }
               ]
             ] == Defmodule.parse(ast, [])
    end
  end
end
