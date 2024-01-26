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

  defguard is_operator(term) when term in [:^, :., :=, :&, :"::", :\\]

  # compactize Kernel calls
  def parse({{:., _, [{:__aliases__, _, [:Kernel]}, term]}, _, arguments}, aliases)
      when is_atom(term),
      do: Parser.parse({term, [], arguments}, aliases)

  # {:., [from_brackets: true, line: 4], [Access, :get]}
  def parse({term, [from_brackets: true, line: _], [from, key]}, aliases) do
    %{
      source: Parser.parse(term, aliases),
      brackets: %{
        from: Parser.parse(from, aliases),
        key: Parser.parse(key, aliases)
      }
    }
  end

  # {:., _, [{:__aliases__, _, [:Mix, :Project]}, :config]}
  def parse({:., _, [{:__aliases__, _, context}, function]}, aliases) do
    %{
      body: to_string(function),
      kind: :call,
      context: Parser.expand_module(context, aliases)
    }
  end

  def parse({:=, _, [left, {name, _, nil}]}, aliases),
    do: %{
      body: to_string(name),
      kind: :match,
      term: Parser.parse(left, aliases)
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

  def parse({:\\, _, [arg, default]}, aliases) do
    %{
      default_arg: %{
        arg: Parser.parse(arg, aliases),
        default_value: Parser.parse(default, aliases)
      }
    }
  end
end
