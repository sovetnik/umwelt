defmodule Umwelt.Parser.StructureTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Structure

  import Umwelt.Parser.Structure, only: [is_structure: 1]

  describe "guard" do
    test "is_structure" do
      [:%, :%{}, :<<>>]
      |> Enum.map(&assert is_structure(&1))
    end
  end

  test "%{} map macro" do
    {:ok, ast} = Code.string_to_quoted("%{bar: :baz, fizz: :buzz}")

    assert %{
             context: [],
             keyword: [
               %{
                 elements: [
                   %{body: "bar", kind: :literal, type: [:Atom]},
                   %{body: "baz", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               },
               %{
                 elements: [
                   %{body: "fizz", kind: :literal, type: [:Atom]},
                   %{body: "buzz", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               }
             ],
             kind: :structure,
             body: :map
           } == Structure.parse(ast, [])
  end

  test "%{ => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{:\"23\" => :foo, :bar => :baz}")

    assert %{
             context: [],
             keyword: [
               %{
                 elements: [
                   %{body: "23", kind: :literal, type: [:Atom]},
                   %{body: "foo", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               },
               %{
                 elements: [
                   %{body: "bar", kind: :literal, type: [:Atom]},
                   %{body: "baz", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               }
             ],
             kind: :structure,
             body: :map
           } == Structure.parse(ast, [])
  end

  test "%{[] => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{[23] => :foo, :bar => :baz}")

    assert %{
             context: [],
             keyword: [
               %{
                 elements: [
                   [%{body: "23", kind: :literal, type: [:Integer]}],
                   %{body: "foo", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               },
               %{
                 elements: [
                   %{body: "bar", kind: :literal, type: [:Atom]},
                   %{body: "baz", kind: :literal, type: [:Atom]}
                 ],
                 body: :tuple,
                 kind: :structure
               }
             ],
             kind: :structure,
             body: :map
           } == Structure.parse(ast, [])
  end

  test "%Foo{} macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{bar: :baz}")

    assert %{
             context: [:Foo],
             keyword: [
               %{
                 body: :tuple,
                 kind: :structure,
                 elements: [
                   %{type: [:Atom], body: "bar", kind: :literal},
                   %{type: [:Atom], body: "baz", kind: :literal}
                 ]
               }
             ],
             kind: :structure,
             body: :map
           } == Structure.parse(ast, [])
  end

  test "% macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert %{
             context: [:Foo],
             kind: :structure,
             body: :map,
             keyword: []
           } == Structure.parse(ast, [])
  end
end
