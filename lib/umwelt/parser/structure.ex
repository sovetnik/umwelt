defmodule Umwelt.Parser.Structure do
  @moduledoc "Parses %Structure{} and <<>> AST"

  alias Umwelt.Parser

  defguard is_structure(term) when term in [:%, :%{}, :<<>>]

  def parse({:%, _, [{:__aliases__, _, _} = ast, {:%{}, _, children}]}, aliases) do
    %{
      kind: :Value,
      type: Parser.parse(ast, aliases),
      keyword: Parser.parse(children, aliases)
    }
  end

  def parse({:%{}, _, children}, aliases),
    do: %{
      kind: :Value,
      type: [:Map],
      keyword: Parser.parse(children, aliases)
    }

  def parse({:<<>>, _, children}, aliases),
    do: %{
      kind: :Value,
      type: [:Bitstring],
      bits: Parser.parse(children, aliases)
    }
end
