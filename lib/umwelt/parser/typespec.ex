defmodule Umwelt.Parser.Typespec do
  @moduledoc "Parses Typespec definition AST"

  import Umwelt.Helpers

  alias Umwelt.Parser

  def parse(
        {:@, _, [{term, _, [{:"::", _, [left, right]}]}]},
        aliases
      ) do
    parse([{term, [], [left, right]}], aliases, [])
  end

  def parse([{:"::", _, _} = ast], aliases, _context) do
    Parser.parse(ast, aliases)
  end

  def parse([{type, _, [left, right]}], aliases, _context) do
    %{
      kind: upper_atom(type),
      type: Parser.parse(left, aliases),
      spec: Parser.parse(right, aliases)
    }
  end
end
