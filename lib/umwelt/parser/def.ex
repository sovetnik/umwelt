defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  require Logger
  @log_message "Unknown AST skipped in Def.parse"
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

  def parse(ast, _aliases) do
    Logger.warning("#{@log_message}/2\n #{inspect(ast)}")
    nil
  end

  # simple call node
  defp parse_call({term, _, children} = ast, aliases)
       when is_atom_macro(ast),
       do: %{
         kind: :Function,
         body: to_string(term),
         arguments: Enum.map(children, &parse_arg(&1, aliases))
       }

  defp parse_arg([], _), do: %{body: "_", type: [:List], kind: :Value}

  defp parse_arg([{:|, _, [head, tail]}], aliases),
    do: %{
      body: "_",
      type: [:List],
      kind: :Value,
      head: Parser.parse(head, aliases),
      tail: Parser.parse(tail, aliases)
    }

  defp parse_arg({:=, _, [left, {name, _, nil}]}, aliases) do
    left
    |> Parser.parse(aliases)
    |> Map.put(:body, to_string(name))
    |> Map.put(:kind, :Variable)
  end

  defp parse_arg(ast, aliases) do
    ast
    |> Parser.parse(aliases)
    |> Map.put_new(:body, "_")
    |> Map.put_new(:kind, :Value)
  end
end
