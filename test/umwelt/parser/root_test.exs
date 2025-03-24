defmodule Umwelt.Parser.RootTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.{
    Attribute,
    Call,
    Concept,
    Field,
    Function,
    Literal,
    Root,
    Structure,
    Value,
    Variable
  }

  alias Umwelt.Parser

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
               %Root{name: "Foo", context: ["Foo"]},
               [
                 %Concept{
                   name: "Bar",
                   note: "Foobar description",
                   context: ["Foo", "Bar"],
                   attrs: [
                     %Attribute{
                       name: "foo",
                       value: %Value{type: %Literal{type: :atom}, body: "bar"}
                     }
                   ],
                   functions: [
                     %Function{
                       body: %Call{
                         name: "foo",
                         arguments: [%Variable{body: "bar", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       note: "bar -> baz"
                     }
                   ]
                 },
                 [
                   %Concept{
                     name: "Baz",
                     note: "Baz description",
                     context: ["Foo", "Bar", "Baz"],
                     functions: [
                       %Function{
                         body: %Call{
                           name: "bar",
                           arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                           type: %Literal{type: :anything}
                         },
                         impl: %Value{type: %Literal{type: :boolean}, body: "true"}
                       }
                     ]
                   }
                 ]
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{
                 context: ["Root"],
                 functions: [
                   %Function{
                     body: %Call{
                       name: "root_one",
                       arguments: [%Variable{body: "once", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
                     private: false
                   },
                   %Function{
                     body: %Call{
                       name: "root_two",
                       arguments: [%Variable{body: "twice", type: %Literal{type: :anything}}],
                       type: %Literal{type: :anything}
                     },
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
                         private: false
                       }
                     ],
                     name: "Baz",
                     note: "Baz description"
                   }
                 ]
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{name: "Foo", context: ["Foo"]},
               [
                 %Concept{name: "Bar", context: ["Foo", "Bar"]},
                 [%Concept{name: "Baz", context: ["Foo", "Bar", "Baz"]}]
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{context: ["Foo"], name: "Foo"},
               [
                 %Concept{context: ["Foo", "Bar"], name: "Bar"},
                 [%Concept{context: ["Foo", "Bar", "Baz"], name: "Baz"}]
               ]
             ] == Parser.Root.parse(ast)
    end

    test "empty inner module expands aliases deeply" do
      {:ok, ast} =
        """
          defmodule Foo.Bar.Baz do
          end
        """
        |> Code.string_to_quoted()

      assert [
               %Root{context: ["Foo"], name: "Foo"},
               [
                 %Concept{context: ["Foo", "Bar"], name: "Bar"},
                 [%Concept{context: ["Foo", "Bar", "Baz"], name: "Baz"}]
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{name: "Foo", context: ["Foo"]},
               [
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
                       private: false
                     },
                     %Function{
                       body: %Call{
                         name: "bar",
                         arguments: [%Variable{body: "baz", type: %Literal{type: :anything}}],
                         type: %Literal{type: :anything}
                       },
                       private: false
                     }
                   ]
                 }
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{name: "Foo", context: ["Foo"]},
               [
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
               ]
             ] == Parser.Root.parse(ast)
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
               %Root{name: "Foo", context: ["Foo"]},
               [%Concept{name: "Bar", context: ["Foo", "Bar"], note: "Foobar description"}]
             ] == Parser.Root.parse(ast)
    end
  end
end
