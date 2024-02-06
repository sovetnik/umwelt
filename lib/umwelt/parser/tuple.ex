defmodule Umwelt.Parser.Tuple do
  @moduledoc "Parses Tuple AST"

  alias Umwelt.Parser

  def parse({:{}, _, children}, aliases),
    do: %{
      type: [:Tuple],
      elements: Parser.parse(children, aliases)
    }

  def parse(tuple, aliases) when is_tuple(tuple) do
    result =
      tuple
      |> Tuple.to_list()
      |> Parser.parse(aliases)

    %{
      type: [:Tuple],
      elements: result
    }
  end
end
