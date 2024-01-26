defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({:def, _, [{:when, _, _} = ast, [do: _]]}, aliases)
      when is_atom_macro(ast),
      do: Parser.parse(ast, aliases)

  def parse({:def, _, [{function, _, nil}, [do: _]]}, aliases) do
    Parser.parse({function, [], []}, aliases)
  end

  def parse({:def, _, [ast, [do: _]]}, aliases)
      when is_atom_macro(ast) do
    Parser.parse(ast, aliases)
  end

  def parse({:def, _, [function]}, aliases)
      when is_atom_macro(function) do
    Parser.parse(function, aliases)
  end
end
