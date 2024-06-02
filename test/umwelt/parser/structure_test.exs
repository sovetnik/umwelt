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
                   %{body: "fizz", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "buzz", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
               }
             ],
             kind: :Value,
             type: %{kind: :Structure, type: :map}
           } == Structure.parse(ast, [])
  end

  test "%var{} map macro" do
    {:ok, ast} = Code.string_to_quoted("%var{fizz: :buzz}")

    assert %{
             body: "var",
             kind: :Variable,
             type: %{kind: :Structure, type: :map},
             keyword: [
               %{
                 elements: [
                   %{body: "fizz", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "buzz", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
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
                   %{body: "fizz", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "buzz", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
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
                   %{body: "23", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "foo", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
               },
               %{
                 elements: [
                   %{body: "bar", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "baz", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
               }
             ],
             kind: :Value,
             type: %{kind: :Structure, type: :map}
           } == Structure.parse(ast, [])
  end

  test "%{[] => } map macro" do
    {:ok, ast} = Code.string_to_quoted("%{[23] => :foo, :bar => :baz}")

    assert %{
             keyword: [
               %{
                 elements: [
                   %{
                     type: %{kind: :Structure, type: :list},
                     values: [
                       %{type: %{kind: :Literal, type: :integer}, body: "23", kind: :Value}
                     ],
                     kind: :Value
                   },
                   %{body: "foo", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
               },
               %{
                 elements: [
                   %{body: "bar", kind: :Value, type: %{kind: :Literal, type: :atom}},
                   %{body: "baz", kind: :Value, type: %{kind: :Literal, type: :atom}}
                 ],
                 kind: :Value,
                 type: %{kind: :Structure, type: :tuple}
               }
             ],
             kind: :Value,
             type: %{kind: :Structure, type: :map}
           } == Structure.parse(ast, [])
  end
end
