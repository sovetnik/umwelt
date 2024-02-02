defmodule Umwelt.Parser.Structure do
  @moduledoc "Parses %Structure{} and <<>> AST"

  alias Umwelt.Parser

  defguard is_structure(term) when term in [:%, :%{}, :<<>>]

  def parse(
        {:%, _, [{:__aliases__, _, _} = ast, {:%{}, _, children}]},
        aliases
      ) do
    %{
      body: :map,
      kind: :structure,
      context: Parser.parse(ast, aliases),
      keyword: Parser.parse(children, aliases)
    }
  end

  def parse({:%{}, _, children}, aliases) do
    %{
      body: :map,
      kind: :structure,
      context: [],
      keyword: Parser.parse(children, aliases)
    }
  end

  def parse({:<<>>, _, children}, aliases) do
    %{
      body: :bitstring,
      kind: :structure,
      bits: Parser.parse(children, aliases)
    }
  end
end
