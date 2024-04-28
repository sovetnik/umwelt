defmodule Umwelt.Parser.Tuple do
  @moduledoc "Parses Tuple AST"

  alias Umwelt.Parser

  def parse({:{}, _, children}, aliases),
    do: %{
      kind: :Value,
      type: [:Tuple],
      elements: Parser.parse_list(children, aliases)
    }

  def parse(tuple, aliases) when is_tuple(tuple) do
    result =
      tuple
      |> Tuple.to_list()
      |> Parser.parse_list(aliases)

    %{
      kind: :Value,
      type: [:Tuple],
      elements: result
    }
  end
end
