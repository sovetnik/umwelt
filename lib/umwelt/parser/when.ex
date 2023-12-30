defmodule Umwelt.Parser.When do
  @moduledoc "Parses Method AST"

  alias Umwelt.Parser

  def parse(
        {:when, _,
         [
           {method, _, arguments},
           {_, _, _} = either
         ]},
        aliases
      ) do
    %{}
    |> Map.put(:method, method)
    |> Map.put(:args, parse_args(arguments, aliases))
    |> Map.put(:guards, parse_guards(either))
  end

  def parse_guards({_, _, _} = ast),
    do: parse_guards(ast, %{})

  def parse_guards({:or, _, either}, acc) do
    either
    |> Enum.reduce(acc, fn
      {:or, _, either}, acc ->
        parse_guards({:or, nil, either}, acc)

      {guard, _, either}, acc ->
        parse_guards({guard, nil, either}, acc)
    end)
  end

  def parse_guards({guard, _, [{arg, _, nil}]}, acc),
    do: Map.put(acc, arg, [guard | acc[arg] || []])

  def parse_args(arguments, aliases),
    do: arguments |> Enum.map(&Parser.parse(&1, aliases))
end
