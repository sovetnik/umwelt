defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

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
               functions: [
                 %{
                   arguments: [%{body: "bar", kind: :literal, type: [:Variable]}],
                   body: "foo",
                   kind: :function,
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
                 functions: [
                   %{
                     arguments: [%{body: "baz", kind: :literal, type: [:Variable]}],
                     body: "bar",
                     impl: %{body: "true", kind: :literal, type: [:Boolean]},
                     kind: :function
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
                   kind: :function
                 },
                 %{
                   arguments: [%{type: [:Variable], body: "twice", kind: :literal}],
                   body: "root_two",
                   kind: :function
                 }
               ],
               context: [:Root],
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
                     kind: :function
                   }
                 ],
                 context: [:Root, :Foo],
                 body: "Foo",
                 kind: :space,
                 note: "Foo description"
               },
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
                   body: "Baz",
                   kind: :space,
                   note: "Baz description"
                 }
               ],
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
                   body: "Bar",
                   kind: :space,
                   note: "Bar description"
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
             %{context: [:Foo, :Bar], body: "Bar", kind: :space},
             [%{context: [:Foo, :Bar, :Baz], body: "Baz", kind: :space}]
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
               functions: [
                 %{
                   arguments: [%{type: [:Variable], body: "bar", kind: :literal}],
                   body: "foo",
                   kind: :function
                 }
               ],
               note: "Foobar description"
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
             %{context: [:Foo, :Bar], body: "Bar", kind: :space, note: "Foobar description"}
           ] == Defmodule.parse(ast, [])
  end

  test "empty module" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
        end
      """
      |> Code.string_to_quoted()

    assert [%{context: [:Foo, :Bar], body: "Bar", kind: :space}] ==
             Defmodule.parse(ast, [])
  end
end
