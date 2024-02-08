defmodule Umwelt.Parser.Operator do
  @moduledoc """
    Parses Operator AST:

    ^ - pin operator
    . - dot operator
    = - match operator
    & - capture operator
    :: - type operator
  """

  alias Umwelt.Parser

  defguard is_special_operator(term)
           when term in [:^, :., :=, :&, :"::"]

  defguard is_comparison_operator(term)
           when term in [:==, :!=, :===, :!==, :<, :<=, :>, :>=]

  defguard is_other_operator(term)
           when term in [:\\, :in, :when]

  defguard is_relaxed_bool_operator(term)
           when term in [:&&, :||, :!]

  defguard is_strict_bool_operator(term)
           when term in [:and, :or, :not]

  defguard is_unary(term)
           when term in [:!, :^, :not, :&]

  defguard is_operator(term)
           when is_special_operator(term) or
                  is_comparison_operator(term) or
                  is_other_operator(term) or
                  is_relaxed_bool_operator(term) or
                  is_strict_bool_operator(term)

  # compactize Kernel calls
  def parse({{:., _, [{:__aliases__, _, [:Kernel]}, term]}, _, arguments}, aliases)
      when is_atom(term),
      do: Parser.parse({term, [], arguments}, aliases)

  # qualified call node
  def parse({{:., _, [{:__aliases__, _, module}, term]}, _, arguments}, aliases)
      when is_atom(term),
      do: %{
        body: to_string(term),
        context: module,
        kind: :Call,
        arguments: Parser.parse(arguments, aliases)
      }

  def parse(
        {{:., [from_brackets: true, line: _], [Access, :get]}, [from_brackets: true, line: _],
         [from, key]},
        aliases
      ),
      do: %{
        kind: :Access,
        source: Parser.parse(from, aliases),
        key: Parser.parse(key, aliases)
      }

  def parse({:=, _, [left, {name, _, nil}]}, aliases),
    do: %{
      body: to_string(name),
      kind: :Match,
      term: Parser.parse(left, aliases)
    }

  def parse({:\\, _, [arg, []]}, aliases) do
    arg
    |> Parser.parse(aliases)
    |> Map.put_new(:default, %{type: [:List]})
  end

  def parse({:\\, _, [arg, default]}, aliases) do
    arg
    |> Parser.parse(aliases)
    |> Map.put_new(:default, Parser.parse(default, aliases))
  end

  def parse({:in, _, [left, right]}, aliases) when is_list(right),
    do: %{
      body: "membership",
      kind: :Operator,
      left: Parser.parse(left, aliases),
      right: Parser.parse(right, aliases)
    }

  # def parse({:^, _, [left, {name, _, nil}]}, aliases),
  #   do: %{
  #     body: to_string(name),
  #     kind: :pin,
  #     term: Parser.parse(left, aliases)
  #   }

  # def parse({:&, _, [left, {name, _, nil}]}, aliases),
  #   do: %{
  #     body: to_string(name),
  #     kind: :capture,
  #     term: Parser.parse(left, aliases)
  #   }

  # def parse({:"::", _, [left, {name, _, nil}]}, aliases),
  #   do: %{
  #     body: to_string(name),
  #     kind: :type,
  #     term: Parser.parse(left, aliases)
  #   }

  def parse({term, _, [expr]}, aliases) when is_unary(term),
    do: %{
      body: to_string(term),
      kind: :Operator,
      expr: Parser.parse(expr, aliases)
    }

  def parse({term, _, [left, right]}, aliases),
    do: %{
      body: to_string(term),
      kind: :Operator,
      left: Parser.parse(left, aliases),
      right: Parser.parse(right, aliases)
    }
end
