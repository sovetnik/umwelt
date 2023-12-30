defmodule Umwelt.Parser.Tuple do
  @moduledoc "Parses Tuple AST"

  alias Umwelt.Parser

  def parse({:{}, _, children}, aliases),
    do: %{tuple: parse_children(children, aliases)}

  def parse(tuple, aliases) when is_tuple(tuple) do
    result =
      tuple
      |> Tuple.to_list()
      |> Parser.parse(aliases)

    %{tuple: result}
  end

  def parse_children(children, aliases),
    do: children |> Parser.parse(aliases)
end
