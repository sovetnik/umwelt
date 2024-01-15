defmodule Umwelt.Parser.Guard do
  @moduledoc "Parses Guard AST"

  alias Umwelt.Parser

  def parse(
        {:when, _,
         [
           {function, _, arguments},
           {_, _, _} = either
         ]},
        aliases
      ) do
    %{}
    |> Map.put(:function, function)
    |> Map.put(:args, parse_args(arguments, aliases))
    |> Map.put(:guards, parse_guards(either, aliases))
  end

  # other guards, like is_*
  def parse_guards({term, _, _} = ast, aliases)
      when is_atom(term) do
    Parser.parse(ast, aliases)
  end

  def parse_args(arguments, aliases),
    do: arguments |> Enum.map(&Parser.parse(&1, aliases))
end
