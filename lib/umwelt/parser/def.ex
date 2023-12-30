defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Method AST"

  alias Umwelt.Parser

  def parse({:def, _, [{:when, _, _} = ast, [do: _]]}, aliases),
    do: Parser.When.parse(ast, aliases)

  def parse({:def, _, [{method, _, arguments}, [do: _]]}, aliases) do
    %{}
    |> Map.put(:method, method)
    |> Map.put(:args, parse_args(arguments, aliases))
  end

  defp parse_args(nil, _aliases), do: []

  defp parse_args(arguments, aliases),
    do: arguments |> Parser.parse(aliases)
end
