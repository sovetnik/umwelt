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
             [
               %{
                 args: [%{body: "baz", kind: [:Variable]}],
                 function: :bar,
                 impl: [%{body: "true", kind: [:Boolean]}]
               },
               %{context: [:Foo, :Bar, :Baz], moduledoc: ["Baz description"]}
             ],
             %{args: [%{body: "bar", kind: [:Variable]}], function: :foo, doc: ["bar -> baz"]},
             %{context: [:Foo, :Bar], moduledoc: ["Foobar description"]}
           ] == Defmodule.parse(ast, [])
  end

  test "deep inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Root do
          @moduledoc "Foo description"
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
             [
               [
                 %{args: [%{body: "foo", kind: [:Variable]}], function: :baz},
                 %{context: [:Root, :Foo, :Baz], moduledoc: ["Baz description"]}
               ],
               [
                 %{args: [%{body: "baz", kind: [:Variable]}], function: :bar},
                 %{context: [:Root, :Foo, :Bar], moduledoc: ["Bar description"]}
               ],
               %{args: [%{body: "bar", kind: [:Variable]}], function: :foo},
               %{context: [:Root, :Foo], moduledoc: ["Foo description"]}
             ],
             %{args: [%{body: "twice", kind: [:Variable]}], function: :root_two},
             %{args: [%{body: "once", kind: [:Variable]}], function: :root_one},
             %{context: [:Root], moduledoc: ["Foo description"]}
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
             [%{context: [:Foo, :Bar, :Baz]}],
             %{context: [:Foo, :Bar]}
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
               args: [
                 %{body: "bar", kind: [:Variable]}
               ],
               function: :foo
             },
             %{
               context: [:Foo, :Bar],
               moduledoc: ["Foobar description"]
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
               moduledoc: ["Foobar description"]
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
               context: [:Foo, :Bar]
             }
           ] == Defmodule.parse(ast, [])
  end
end
