defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  alias Umwelt.Parser

  def parse({:def, _, [{:when, _, _} = ast, [do: _]]}, aliases),
    do: parse(ast, aliases)

  def parse({:def, _, [{function, _, nil}, [do: _]]}, _aliases) do
    %{
      body: to_string(function),
      kind: :function,
      arguments: []
    }
  end

  def parse({:def, _, [{function, _, arguments}, [do: _]]}, aliases) do
    %{
      body: to_string(function),
      kind: :function,
      arguments: Parser.parse(arguments, aliases)
    }
  end

  def parse(
        {:when, _,
         [
           {function, _, arguments},
           {_, _, _} = either
         ]},
        aliases
      ) do
    %{
      body: to_string(function),
      kind: :function,
      arguments: parse_args(arguments, aliases),
      guards: parse_guards(either, aliases)
    }
  end

  # other guards, like is_*
  def parse_guards({term, _, _} = ast, aliases)
      when is_atom(term) do
    Parser.parse(ast, aliases)
  end

  def parse_args(arguments, aliases),
    do: arguments |> Enum.map(&Parser.parse(&1, aliases))
end
