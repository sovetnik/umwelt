defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({:def, _, [{:when, _, _} = ast, [do: _]]}, aliases)
      when is_atom_macro(ast),
      do: Parser.parse(ast, aliases)

  def parse({:def, _, [{function, _, nil}, [do: _]]}, aliases),
    do: parse_call({function, [], []}, aliases)

  def parse({:def, _, [ast, [do: _]]}, aliases)
      when is_atom_macro(ast),
      do: parse_call(ast, aliases)

  def parse({:def, _, [function]}, aliases)
      when is_atom_macro(function),
      do: parse_call(function, aliases)

  # simple call node
  defp parse_call({term, _, children} = ast, aliases)
       when is_atom_macro(ast),
       do: %{
         kind: :call,
         body: to_string(term),
         arguments: Enum.map(children, &parse_arg(&1, aliases))
       }

  defp parse_arg([], _), do: %{body: "_", type: [:List], kind: :value}

  defp parse_arg([{:|, _, [head, tail]}], aliases),
    do: %{
      body: "_",
      type: [:List],
      kind: :value,
      head: Parser.parse(head, aliases),
      tail: Parser.parse(tail, aliases)
    }

  defp parse_arg({:=, _, [left, {name, _, nil}]}, aliases) do
    left
    |> Parser.parse(aliases)
    |> Map.put_new(:body, to_string(name))
    |> Map.put_new(:kind, :variable)
  end

  defp parse_arg(ast, aliases) do
    ast
    |> Parser.parse(aliases)
    |> Map.put_new(:body, "_")
    |> Map.put_new(:kind, :value)
  end
end
