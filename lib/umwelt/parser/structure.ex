defmodule Umwelt.Parser.Structure do
  @moduledoc "Parses %Structure{} and <<>> AST"

  alias Umwelt.Parser

  defguard is_structure(term) when term in [:%, :%{}, :<<>>]

  def parse({:%, _, [{:__aliases__, _, _} = ast, {:%{}, _, children}]}, aliases),
    do: %{
      kind: :Value,
      type: Parser.parse(ast, aliases),
      keyword: Parser.parse_list(children, aliases)
    }

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

  def parse({:<<>>, _, children}, aliases) do
    literal_bits =
      children
      |> Enum.reject(&match?({_, _, _}, &1))
      |> Parser.maybe_list_parse(aliases)

    %{
      kind: :Value,
      type: [:Bitstring],
      bits: literal_bits
    }
  end
end
