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
    {:ok, ast} = Code.string_to_quoted("%{fizz: :buzz}")

    assert %{
             keyword: [
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

  test "%var{} map macro" do
    {:ok, ast} = Code.string_to_quoted("%var{fizz: :buzz}")

    assert %{
             body: "var",
             kind: :Variable,
             type: [:Map],
             keyword: [
               %{
                 elements: [
                   %{body: "fizz", kind: :Value, type: [:Atom]},
                   %{body: "buzz", kind: :Value, type: [:Atom]}
                 ],
                 kind: :Value,
                 type: [:Tuple]
               }
             ]
           } == Structure.parse(ast, [])
  end

  test "typed %Buzz{} map macro" do
    {:ok, ast} = Code.string_to_quoted("%Foobar{fizz: :buzz}")

    assert %{
             keyword: [
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
             type: %{name: :Foobar, path: [:Foobar], kind: :Alias}
           } == Structure.parse(ast, [])
  end

  test "%{ => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{:\"23\" => :foo, :bar => :baz}")

    assert %{
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
             keyword: [
               %{
                 elements: [
                   %{
                     type: [:List],
                     values: [%{type: [:Integer], body: "23", kind: :Value}],
                     kind: :Value
                   },
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
end
