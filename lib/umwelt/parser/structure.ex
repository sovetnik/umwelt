defmodule Umwelt.Parser.Structure do
  @moduledoc "Parses %Structure{} and <<>> AST"

  alias Umwelt.Parser

  defguard is_structure(term) when term in [:%, :%{}, :<<>>]

  def parse({:%, _, [{:__aliases__, _, _} = ast, {:%{}, _, children}]}, aliases) do
    %{
      kind: :Value,
      type: Parser.parse(ast, aliases),
      keyword: Parser.parse_list(children, aliases)
    }
  end

  def parse({:%, _, [{term, _, nil}, {:%{}, _, children}]}, aliases),
    do: %{
      kind: :Variable,
      body: to_string(term),
      type: [:Map],
      keyword: Parser.parse_list(children, aliases)
    }

  def parse({:%{}, _, children}, aliases),
    do: %{
      kind: :Value,
      type: [:Map],
      keyword: Parser.parse_list(children, aliases)
    }

  def parse({:<<>>, _, children}, aliases),
    do: %{
      kind: :Value,
      type: [:Bitstring],
      bits: Parser.parse_list(children, aliases)
    }
end
