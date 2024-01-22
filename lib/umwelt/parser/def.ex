defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({:def, _, [{:when, _, [ast, guards]}, [do: _]]}, aliases)
      when is_atom_macro(ast) do
    ast
    |> parse_fun_with_args(aliases)
    |> Map.put(:guards, Parser.parse(guards, aliases))
  end

  def parse({:def, _, [{function, _, nil}, [do: _]]}, aliases) do
    parse_fun_with_args({function, [], []}, aliases)
  end

  def parse({:def, _, [ast, [do: _]]}, aliases)
      when is_atom_macro(ast) do
    parse_fun_with_args(ast, aliases)
  end

  defp parse_fun_with_args({function, _, arguments}, aliases) do
    %{
      body: to_string(function),
      kind: :function,
      arguments: Parser.parse(arguments, aliases)
    }
  end
end
