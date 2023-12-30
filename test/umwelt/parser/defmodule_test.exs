defmodule Umwelt.Parser.DefmoduleTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Defmodule

  test "inner module expands aliases" do
    {:ok, ast} =
      """
        defmodule Foo.Bar do
          @moduledoc "Foobar description"
          def foo(bar) do
            :baz
          end
          defmodule Baz do
            @moduledoc "Baz description"
            def bar(baz) do
              :foo
            end
          end
        end
      """
      |> Code.string_to_quoted()

    assert [
             [
               %{args: [%{body: "baz", kind: [:Undefined]}], method: :bar},
               %{context: [:Foo, :Bar, :Baz], moduledoc: ["Baz description"]}
             ],
             %{args: [%{body: "bar", kind: [:Undefined]}], method: :foo},
             %{context: [:Foo, :Bar], moduledoc: ["Foobar description"]}
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

  test "just a module with method" do
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
                 %{body: "bar", kind: [:Undefined]}
               ],
               method: :foo
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
