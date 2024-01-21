defmodule Umwelt.Parser do
  @moduledoc "Extracts metadata from AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_macro: 1]
  def read_ast({:error, msg}), do: {:error, msg}

  def read_ast({:ok, code}),
    do: Code.string_to_quoted(code)

  def parse({:ok, ast}),
    do: ast |> parse([]) |> index()

  def parse_root({:ok, ast}),
    do: ast |> Parser.Root.parse() |> index()

  def parse(ast, aliases) when is_macro(ast),
    do: Parser.Macro.parse(ast, aliases)

  def parse(ast, aliases) when is_tuple(ast) and tuple_size(ast) == 2,
    do: Parser.Tuple.parse(ast, aliases)

  def parse(ast, aliases) when is_list(ast),
    do: Enum.map(ast, &parse(&1, aliases))

  def parse(ast, _aliases),
    do: Parser.Literal.parse(ast)

  defp index(parsed) do
    parsed
    |> inner_modules()
    |> Enum.map(&index(&1))
    |> Enum.reduce(index_root(parsed), &Map.merge(&2, &1))
  end

  defp index_root(parsed) do
    parsed
    |> root_module()
    |> Enum.reduce(%{}, &Map.put(&2, context(&1), List.first(&1)))
  end

  defp root_module(parsed),
    do: [parsed |> Enum.filter(&is_map/1)]

  defp inner_modules(parsed),
    do: parsed |> Enum.filter(&is_list/1)

  defp context(module) do
    module
    |> Enum.flat_map(fn
      %{context: context} -> List.wrap(context)
      _ -> []
    end)
  end
end
