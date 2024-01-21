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
           {_, _, _} = guards
         ]},
        aliases
      ) do
    %{
      body: to_string(function),
      kind: :function,
      arguments: Parser.parse(arguments, aliases),
      guards: Parser.parse(guards, aliases)
    }
  end
end
