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
                   %{body: "bar", kind: :Value, type: [:Atom]},
                   %{body: "baz", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "fizz", kind: :Value, type: [:Atom]},
                   %{body: "buzz", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               }
             ],
             kind: :Value,
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "%{ => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{:\"23\" => :foo, :bar => :baz}")

    assert %{
             context: [],
             keyword: [
               %{
                 elements: [
                   %{body: "23", kind: :Value, type: [:Atom]},
                   %{body: "foo", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "bar", kind: :Value, type: [:Atom]},
                   %{body: "baz", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               }
             ],
             kind: :Value,
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "%{[] => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{[23] => :foo, :bar => :baz}")

    assert %{
             context: [],
             keyword: [
               %{
                 elements: [
                   [%{body: "23", kind: :Value, type: [:Integer]}],
                   %{body: "foo", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "bar", kind: :Value, type: [:Atom]},
                   %{body: "baz", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               }
             ],
             kind: :Value,
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "%Foo{} macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{bar: :baz}")

    assert %{
             context: [:Foo],
             keyword: [
               %{
                 kind: :Value,
                 type: [:Tuple],
                 elements: [
                   %{type: [:Atom], body: "bar", kind: :Value},
                   %{type: [:Atom], body: "baz", kind: :Value}
                 ]
               }
             ],
             kind: :Value,
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "% macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert %{
             context: [:Foo],
             kind: :Value,
             type: [:Map],
             keyword: []
           } == Structure.parse(ast, [])
  end
end
