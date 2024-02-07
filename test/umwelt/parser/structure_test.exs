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
                   %{body: "bar", kind: :value, type: [:Atom]},
                   %{body: "baz", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "fizz", kind: :value, type: [:Atom]},
                   %{body: "buzz", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               }
             ],
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
                   %{body: "23", kind: :value, type: [:Atom]},
                   %{body: "foo", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "bar", kind: :value, type: [:Atom]},
                   %{body: "baz", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               }
             ],
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
                   [%{body: "23", kind: :value, type: [:Integer]}],
                   %{body: "foo", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               },
               %{
                 elements: [
                   %{body: "bar", kind: :value, type: [:Atom]},
                   %{body: "baz", kind: :value, type: [:Atom]}
                 ],
                 type: [:Tuple]
               }
             ],
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "%Foo{} macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{bar: :baz}")

    assert %{
             context: [:Foo],
             keyword: [
               %{
                 type: [:Tuple],
                 elements: [
                   %{type: [:Atom], body: "bar", kind: :value},
                   %{type: [:Atom], body: "baz", kind: :value}
                 ]
               }
             ],
             type: [:Map]
           } == Structure.parse(ast, [])
  end

  test "% macro" do
    {:ok, ast} = Code.string_to_quoted("%Foo{}")

    assert %{
             context: [:Foo],
             type: [:Map],
             keyword: []
           } == Structure.parse(ast, [])
  end
end
