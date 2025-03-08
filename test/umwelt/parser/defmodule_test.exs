defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Alias,
    Attribute,
    Call,
    Concept,
    Field,
    Function,
    Literal,
    Operator,
    Structure,
    Type,
    Unary,
    Value,
    Variable
  }

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
             %Concept{
               name: "StringHelpers",
               context: ["StringHelpers"],
               functions: [
                 %Function{
                   body: %Operator{
                     name: "when",
                     left: %Call{
                       name: "long_word?",
                       arguments: [
                         %Variable{
                           body: "word",
                           type: %Type{
                             name: "word",
                             doc: "A word from the dictionary",
                             spec: %Call{
                               name: "t",
                               context: ["String"],
                               type: %Literal{type: :anything}
                             }
                           }
                         }
                       ],
                       context: ["StringHelpers"],
                       type: %Literal{type: :boolean}
                     },
                     right: %Call{
                       name: "is_binary",
                       arguments: [%Variable{body: "word", type: %Literal{type: :anything}}],
                       context: ["StringHelpers"],
                       type: %Literal{type: :anything}
                     }
                   },
                   private: false
                 }
               ],
               types: [
                 %Type{
                   doc: "A word from the dictionary",
                   name: "word",
                   spec: %Call{context: ["String"], name: "t"}
                 }
               ]
             }
           ] == Defmodule.parse(ast, [])
  end

  test "when arg name is equal in spec and in function " do
    {:ok, ast} =
      """
      defmodule StringHelpers do
        @typedoc "A word from the dictionary"
        @type word :: String.t()

        @spec long_word?(word) :: boolean
        def long_word?(word) when is_binary(word) do
          String.length(word) > 8
        end
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Concept{
               name: "StringHelpers",
               context: ["StringHelpers"],
               functions: [
                 %Function{
                   body: %Operator{
                     name: "when",
                     left: %Call{
                       name: "long_word?",
                       arguments: [
                         %Variable{
                           body: "word",
                           type: %Type{
                             doc: "A word from the dictionary",
                             name: "word",
                             spec: %Call{name: "t", context: ["String"]}
                           }
                         }
                       ],
                       context: ["StringHelpers"],
                       type: %Literal{type: :boolean}
                     },
                     right: %Call{
                       name: "is_binary",
                       arguments: [%Variable{body: "word", type: %Literal{type: :anything}}],
                       context: ["StringHelpers"],
                       type: %Literal{type: :anything}
                     }
                   },
                   impl: nil,
                   private: false
                 }
               ],
               types: [
                 %Type{
                   doc: "A word from the dictionary",
                   spec: %Call{
                     context: ["String"],
                     name: "t",
                     type: %Literal{type: :anything}
                   },
                   name: "word"
                 }
               ]
             }
           ] == Defmodule.parse(ast, [])
  end

  test "when arg name is not equal in spec and in function " do
    {:ok, ast} =
      """
      defmodule StringHelpers do
        @typedoc "A word from the dictionary"
        @type word :: String.t()

        @spec long_word?(word) :: boolean
        def long_word?(bin) when is_binary(bin) do
          String.length(bin) > 8
        end
      end
      """
      |> Code.string_to_quoted()

    assert [
             %Concept{
               name: "StringHelpers",
               context: ["StringHelpers"],
               functions: [
                 %Function{
                   body: %Operator{
                     name: "when",
                     left: %Call{
                       name: "long_word?",
                       arguments: [
                         %Variable{
                           body: "bin",
                           type: %Type{
                             doc: "A word from the dictionary",
                             name: "word",
                             spec: %Call{name: "t", context: ["String"]}
                           }
                         }
                       ],
                       context: ["StringHelpers"],
                       type: %Literal{type: :boolean}
                     },
                     right: %Call{
                       name: "is_binary",
                       arguments: [%Variable{body: "bin", type: %Literal{type: :anything}}],
                       context: ["StringHelpers"],
                       type: %Literal{type: :anything}
                     }
                   },
                   impl: nil,
                   private: false
                 }
               ],
               types: [
                 %Type{
                   doc: "A word from the dictionary",
                   spec: %Call{
                     context: ["String"],
                     name: "t",
                     type: %Literal{type: :anything}
                   },
                   name: "word"
                 }
               ]
             }
           ] == Defmodule.parse(ast, [])
  end

  describe "defstruct with type" do
    test "type" do
      {:ok, ast} =
        """
        defmodule Foo.Bar do
          @moduledoc "Felixir Structure"
          alias Foo.Bar.Baz

          @type buzz :: Buzz.t()
          @type fizz() :: Fizz.t()
          @typedoc "just a word"
          @type word() :: String.t()
          @type t() :: %Foo.Bar{
                  buzz: buzz,
                  fizz: fizz(),
                  name: word(),
                  head: Baz.t(),
                  elements: list
                }

          defstruct buzz: "buzzy",
                    fizz: "fizzy",
                    name: "struct_name",
                    head: nil,
                    elements: []
        end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 name: "Bar",
                 note: "Felixir Structure",
                 context: ["Foo", "Bar"],
                 aliases: [%Alias{name: "Baz", path: ~w[Foo Bar Baz]}],
                 fields: [
                   %Field{
                     name: "buzz",
                     type: %Type{
                       name: "buzz",
                       spec: %Call{name: "t", type: %Literal{type: :anything}, context: ["Buzz"]}
                     },
                     value: %Value{body: "buzzy", type: %Literal{type: :string}}
                   },
                   %Field{
                     name: "fizz",
                     type: %Type{
                       name: "fizz",
                       spec: %Call{name: "t", type: %Literal{type: :anything}, context: ["Fizz"]}
                     },
                     value: %Value{body: "fizzy", type: %Literal{type: :string}}
                   },
                   %Field{
                     name: "name",
                     type: %Type{
                       name: "word",
                       spec: %Call{
                         name: "t",
                         type: %Literal{type: :anything},
                         context: ["String"]
                       }
                     },
                     value: %Value{body: "struct_name", type: %Literal{type: :string}}
                   },
                   %Field{
                     name: "head",
                     type: %Alias{name: "Baz", path: ~w[Foo Bar Baz]},
                     value: %Value{body: "nil", type: %Literal{type: :atom}}
                   },
                   %Field{
                     name: "elements",
                     type: %Literal{type: :list},
                     value: %Structure{type: %Literal{type: :list}}
                   }
                 ],
                 types: [
                   %Type{name: "buzz", spec: %Call{context: ["Buzz"], name: "t"}},
                   %Type{name: "fizz", spec: %Call{context: ["Fizz"], name: "t"}},
                   %Type{
                     doc: "just a word",
                     name: "word",
                     spec: %Call{context: ["String"], name: "t"}
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
    end
  end

  describe "parse type or" do
    test "module" do
      {:ok, ast} =
        """
        defmodule Foo do
          defstruct body: %Baz{}

          @type t :: %__MODULE__{
                  body: Bar.t() | Baz.t(),
                  note: String.t()
                }
        end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 context: ["Foo"],
                 fields: [
                   %Field{
                     name: "body",
                     type: %Operator{
                       name: "alter",
                       left: %Call{name: "t", context: ["Bar"]},
                       right: %Call{name: "t", context: ["Baz"]}
                     },
                     value: %Structure{type: %Alias{name: "Baz", path: ["Baz"]}}
                   }
                 ],
                 name: "Foo"
               }
             ] == Defmodule.parse(ast, [])
    end
  end

  describe "parse part of itself" do
    test "module" do
      {:ok, ast} =
        """
        defmodule Umwelt.Parser.Typespec do
          @moduledoc "Parses Typespec definition AST"

          def parse([{type, _, [left, right]}], aliases, _context) do
            %Type{}
          end
        end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 functions: [
                   %Function{
                     body: %Call{
                       name: "parse",
                       arguments: [
                         %Structure{
                           type: %Literal{type: :list},
                           elements: [
                             %Structure{
                               type: %Literal{type: :tuple},
                               elements: [
                                 %Variable{body: "type", type: %Literal{type: :anything}},
                                 %Variable{body: "_", type: %Literal{type: :anything}},
                                 %Structure{
                                   type: %Literal{type: :list},
                                   elements: [
                                     %Variable{body: "left", type: %Literal{type: :anything}},
                                     %Variable{body: "right", type: %Literal{type: :anything}}
                                   ]
                                 }
                               ]
                             }
                           ]
                         },
                         %Variable{body: "aliases", type: %Literal{type: :anything}},
                         %Variable{body: "_context", type: %Literal{type: :anything}}
                       ],
                       type: %Literal{type: :anything}
                     }
                   }
                 ],
                 context: ["Umwelt", "Parser", "Typespec"],
                 name: "Typespec",
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
               %Concept{
                 name: "StringHelpers",
                 context: ["StringHelpers"],
                 note: "Helpers for string",
                 types: [
                   %Type{
                     doc: "Description of type",
                     name: "word",
                     spec: %Call{context: ["String"], name: "t"}
                   }
                 ]
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
               %Concept{
                 functions: [
                   %Function{
                     body: %Call{
                       name: "days_since_epoch",
                       arguments: [
                         %Variable{body: "year", type: %Literal{type: :integer}},
                         %Variable{body: "month", type: %Literal{type: :integer}},
                         %Variable{body: "day", type: %Literal{type: :integer}}
                       ],
                       type: %Literal{type: :integer}
                     },
                     note: "days between past date and today"
                   }
                 ],
                 context: ["Calendar"],
                 name: "Calendar",
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
               %Concept{
                 name: "Math",
                 context: ["Math"],
                 calls: [
                   %Call{
                     arguments: [
                       %Alias{name: "List", path: ["List"]},
                       %Structure{
                         type: %Literal{type: :list},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{type: %Literal{type: :atom}, body: "only"},
                               %Structure{
                                 type: %Literal{type: :list},
                                 elements: [
                                   %Structure{
                                     type: %Literal{type: :tuple},
                                     elements: [
                                       %Value{type: %Literal{type: :atom}, body: "duplicate"},
                                       %Value{type: %Literal{type: :integer}, body: "2"}
                                     ]
                                   }
                                 ]
                               }
                             ]
                           }
                         ]
                       }
                     ],
                     context: ["Math"],
                     name: "import"
                   }
                 ],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "some_function",
                       type: %Literal{type: :anything}
                     }
                   }
                 ]
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
               %Concept{
                 name: "Math",
                 context: ["Math"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "some_function",
                       type: %Literal{type: :anything}
                     }
                   }
                 ]
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
               %Concept{
                 name: "Mailer",
                 calls: [
                   %Call{
                     arguments: [
                       %Alias{name: "Mailer", path: ~w[Swoosh Mailer]},
                       %Structure{
                         type: %Literal{type: :list},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{type: %Literal{type: :atom}, body: "otp_app"},
                               %Value{type: %Literal{type: :atom}, body: "cryptoid"}
                             ]
                           }
                         ]
                       }
                     ],
                     context: ["Cryptoid", "Mailer"],
                     name: "use"
                   }
                 ],
                 context: ["Cryptoid", "Mailer"]
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
               %Concept{
                 name: "Example",
                 calls: [
                   %Call{
                     arguments: [
                       %Alias{name: "Feature", path: ["Feature"]},
                       %Structure{
                         type: %Literal{type: :list},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{type: %Literal{type: :atom}, body: "option"},
                               %Value{type: %Literal{type: :atom}, body: "value"}
                             ]
                           }
                         ]
                       }
                     ],
                     context: ["Example"],
                     name: "use"
                   }
                 ],
                 context: ["Example"],
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
               %Concept{
                 name: "Example",
                 calls: [
                   %Call{
                     arguments: [
                       %Structure{
                         type: %Literal{type: :list},
                         elements: [
                           %Structure{
                             type: %Literal{type: :tuple},
                             elements: [
                               %Value{type: %Literal{type: :atom}, body: "option"},
                               %Value{type: %Literal{type: :atom}, body: "value"}
                             ]
                           }
                         ]
                       }
                     ],
                     name: "__using__",
                     context: ["Feature"]
                   },
                   %Call{
                     arguments: [%Alias{name: "Feature", path: ["Feature"]}],
                     context: ["Example"],
                     name: "require"
                   }
                 ],
                 context: ["Example"]
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 aliases: [
                   %Alias{name: "Bar", path: ["Foo", "Bar"]},
                   %Alias{name: "Baz", path: ["Foo", "Baz"]}
                 ],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foobar",
                       arguments: [
                         %Operator{
                           name: "match",
                           left: %Structure{type: %Alias{name: "Bar", path: ["Foo", "Bar"]}},
                           right: %Variable{
                             body: "bar",
                             type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                           }
                         },
                         %Operator{
                           name: "match",
                           left: %Structure{type: %Alias{name: "Baz", path: ["Foo", "Baz"]}},
                           right: %Variable{
                             body: "baz",
                             type: %Alias{name: "Baz", path: ["Foo", "Baz"]}
                           }
                         }
                       ],
                       type: %Literal{type: :anything}
                     }
                   }
                 ]
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 aliases: [
                   %Alias{name: "Bar", path: ["Foo", "Bar"]},
                   %Alias{name: "Baz", path: ["Foo", "Baz"]}
                 ],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foobar",
                       arguments: [
                         %Operator{
                           name: "match",
                           left: %Structure{
                             type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                           },
                           right: %Variable{
                             body: "bar",
                             type: %Alias{name: "Bar", path: ["Foo", "Bar"]}
                           }
                         },
                         %Operator{
                           name: "match",
                           left: %Structure{
                             type: %Alias{name: "Baz", path: ["Foo", "Baz"]}
                           },
                           right: %Variable{
                             body: "baz",
                             type: %Alias{name: "Baz", path: ["Foo", "Baz"]}
                           }
                         }
                       ],
                       type: %Literal{type: :anything}
                     }
                   }
                 ]
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 guards: [
                   %Operator{
                     name: "when",
                     left: %Call{
                       arguments: [%Variable{type: %Literal{type: :anything}, body: "term"}],
                       context: ["Foo", "Bar"],
                       name: "is_foobar"
                     },
                     right: %Operator{
                       name: "membership",
                       left: %Variable{type: %Literal{type: :anything}, body: "term"},
                       right: [
                         %Value{type: %Literal{type: :atom}, body: "foo"},
                         %Value{type: %Literal{type: :atom}, body: "bar"}
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Operator{
                       name: "when",
                       left: %Call{
                         name: "foobar",
                         arguments: [%Variable{body: "term", type: %Literal{type: :anything}}],
                         context: ["Foo", "Bar"],
                         type: %Literal{type: :anything}
                       },
                       right: %Call{
                         name: "is_foobar",
                         arguments: [%Variable{body: "term", type: %Literal{type: :anything}}],
                         context: ["Foo", "Bar"],
                         type: %Literal{type: :anything}
                       }
                     },
                     impl: nil,
                     private: false
                   }
                 ],
                 guards: [
                   %Operator{
                     name: "when",
                     left: %Call{
                       arguments: [%Variable{type: %Literal{type: :anything}, body: "term"}],
                       context: ["Foo", "Bar"],
                       name: "is_foobar"
                     },
                     right: %Operator{
                       name: "membership",
                       left: %Variable{type: %Literal{type: :anything}, body: "term"},
                       right: [
                         %Value{type: %Literal{type: :atom}, body: "foo"},
                         %Value{type: %Literal{type: :atom}, body: "bar"}
                       ]
                     }
                   }
                 ]
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
               %Concept{
                 name: "Enumeric",
                 context: ["Enumeric"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "reverse",
                       arguments: [
                         %Variable{body: "income", type: %Literal{type: :anything}},
                         %Operator{
                           name: "default",
                           left: %Variable{body: "outcome", type: %Literal{type: :list}},
                           right: %Structure{type: %Literal{type: :list}}
                         }
                       ],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "reverse",
                       arguments: [
                         %Structure{type: %Literal{type: :list}},
                         %Variable{body: "outcome", type: %Literal{type: :anything}}
                       ],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "reverse",
                       arguments: [
                         %Structure{
                           type: %Literal{type: :list},
                           elements: [
                             %Operator{
                               name: "alter",
                               left: %Variable{body: "h", type: %Literal{type: :anything}},
                               right: %Variable{body: "t", type: %Literal{type: :anything}}
                             }
                           ]
                         },
                         %Variable{body: "outcome", type: %Literal{type: :anything}}
                       ],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   }
                 ]
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 fields: [
                   %Field{
                     name: "foo",
                     type: %Literal{type: :anything},
                     value: %Value{type: %Literal{type: :atom}, body: "nil"}
                   },
                   %Field{
                     name: "tree",
                     type: %Literal{type: :anything},
                     value: %Structure{type: %Literal{type: :map}}
                   }
                 ]
               }
             ] == Defmodule.parse(ast, [])
    end

    test "module with defstruct and fun as default value" do
      {:ok, ast} =
        """
          defmodule Estructura.Lazy do
            defstruct getter: &Estructura.Lazy.id/1, expires_in: :never
          end
        """
        |> Code.string_to_quoted()

      assert [
               %Concept{
                 name: "Lazy",
                 context: ["Estructura", "Lazy"],
                 fields: [
                   %Field{
                     name: "getter",
                     type: %Literal{type: :anything},
                     value: %Unary{
                       name: "&",
                       expr: %Operator{
                         left: %Call{context: ["Estructura", "Lazy"], name: "id"},
                         right: %Value{type: %Literal{type: :integer}, body: "1"},
                         name: "/"
                       }
                     }
                   },
                   %Field{
                     name: "expires_in",
                     type: %Literal{type: :anything},
                     value: %Value{type: %Literal{type: :atom}, body: "never"}
                   }
                 ]
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
               %Concept{
                 name: "Bar",
                 note: "Foobar description",
                 context: ["Foo", "Bar"],
                 fields: [
                   %Field{
                     name: "foo",
                     type: %Literal{type: :anything},
                     value: %Value{type: %Literal{type: :atom}, body: "nil"}
                   },
                   %Field{
                     name: "tree",
                     type: %Literal{type: :anything},
                     value: %Structure{type: %Literal{type: :map}}
                   }
                 ],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "bar",
                       arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "foo",
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     }
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
               %Concept{
                 context: ["Foo", "Bar"],
                 name: "Bar",
                 attrs: [
                   %Attribute{
                     name: "fizbuzz",
                     value: %Structure{
                       elements: [
                         %Value{body: "fizz", type: %Literal{type: :atom}},
                         %Value{body: "buzz", type: %Literal{type: :atom}}
                       ],
                       type: %Literal{type: :tuple}
                     }
                   }
                 ]
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
               %Concept{context: ["Foo", "Bar"], name: "Bar", note: "Foobar description"}
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
               %Concept{name: "Formulae", context: ["Formulae"], note: "Description of Formulae"}
             ] == Defmodule.parse(ast, [])
    end

    test "empty module" do
      {:ok, ast} =
        """
          defmodule Foo.Bar do
          end
        """
        |> Code.string_to_quoted()

      assert [%Concept{context: ["Foo", "Bar"], name: "Bar"}] == Defmodule.parse(ast, [])
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
               %Concept{
                 name: "Bar",
                 context: ["Foo", "Bar"],
                 functions: [
                   %Function{
                     body: %Call{
                       arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                       name: "foo",
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     note: "bar -> baz",
                     private: false
                   }
                 ],
                 note: "Foobar description"
               },
               [
                 %Concept{
                   name: "Baz",
                   context: ["Foo", "Bar", "Baz"],
                   functions: [
                     %Function{
                       body: %Call{
                         name: "bar",
                         arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       impl: %Value{body: "true", type: %Literal{type: :boolean}}
                     }
                   ],
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
               %Concept{
                 context: ["Root"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "root_one",
                       arguments: [%Variable{body: "once", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "root_two",
                       arguments: [%Variable{body: "twice", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     impl: nil,
                     private: false
                   }
                 ],
                 name: "Root",
                 note: "Root description"
               },
               [
                 %Concept{
                   context: ["Root", "Foo"],
                   functions: [
                     %Function{
                       body: %Call{
                         name: "foo",
                         arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       impl: nil,
                       private: false
                     }
                   ],
                   name: "Foo",
                   note: "Foo description"
                 },
                 [
                   %Concept{
                     context: ["Root", "Foo", "Bar"],
                     functions: [
                       %Function{
                         body: %Call{
                           name: "bar",
                           arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                           type: %Literal{type: :anything}
                         },
                         impl: nil,
                         private: false
                       }
                     ],
                     name: "Bar",
                     note: "Bar description"
                   }
                 ],
                 [
                   %Concept{
                     context: ["Root", "Foo", "Baz"],
                     functions: [
                       %Function{
                         body: %Call{
                           name: "baz",
                           arguments: [%Variable{body: "foo", type: %Literal{type: :anything}}],
                           type: %Literal{type: :anything}
                         },
                         impl: nil,
                         private: false
                       }
                     ],
                     name: "Baz",
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
               %Concept{name: "Foo", context: ["Foo"]},
               [
                 %Concept{name: "Bar", context: ["Foo", "Bar"]},
                 [%Concept{name: "Baz", context: ["Foo", "Bar", "Baz"]}]
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
               %Concept{context: ["Foo", "Bar"], name: "Bar"},
               [%Concept{context: ["Foo", "Bar", "Baz"], name: "Baz"}]
             ] == Defmodule.parse(ast, [])
    end
  end

  test "module and struct with fields from  attrs" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @enforce_keys [:index, :states]
          defstruct @enforce_keys
        end
      """
      |> Code.string_to_quoted()

    assert [
             %Concept{
               name: "Bar",
               attrs: [
                 %Attribute{
                   name: "enforce_keys",
                   value: %Structure{
                     type: %Literal{type: :list},
                     elements: [
                       %Value{body: "index", type: %Literal{type: :atom}},
                       %Value{body: "states", type: %Literal{type: :atom}}
                     ]
                   }
                 }
               ],
               context: ["Foo", "Bar"],
               fields: [
                 %Field{
                   name: "index",
                   type: %Literal{type: :anything},
                   value: %Value{type: %Literal{type: :atom}, body: "nil"}
                 },
                 %Field{
                   name: "states",
                   type: %Literal{type: :anything},
                   value: %Value{type: %Literal{type: :atom}, body: "nil"}
                 }
               ]
             }
           ] ==
             Defmodule.parse(ast, [])
  end

  test "module and struct with enforce_keys" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @enforce_keys [:index, :states]
          defstruct index: %{}, states: %{}
        end
      """
      |> Code.string_to_quoted()

    assert [
             %Concept{
               name: "Bar",
               note: "",
               aliases: [],
               attrs: [
                 %Attribute{
                   name: "enforce_keys",
                   value: %Structure{
                     type: %Literal{type: :list},
                     elements: [
                       %Value{body: "index", type: %Literal{type: :atom}},
                       %Value{body: "states", type: %Literal{type: :atom}}
                     ]
                   }
                 }
               ],
               calls: [],
               context: ["Foo", "Bar"],
               fields: [
                 %Field{
                   name: "index",
                   type: %Literal{type: :anything},
                   value: %Structure{type: %Literal{type: :map}, elements: []}
                 },
                 %Field{
                   name: "states",
                   type: %Literal{type: :anything},
                   value: %Structure{type: %Literal{type: :map}, elements: []}
                 }
               ],
               functions: [],
               guards: [],
               specs: [],
               types: []
             }
           ] ==
             Defmodule.parse(ast, [])
  end
end
