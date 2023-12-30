defmodule Umwelt.Parser do
  @moduledoc "Extracts metadata from AST"

  alias Umwelt.Parser

  def read_ast({:error, msg}), do: {:error, msg}

  def read_ast({:ok, code}),
    do: Code.string_to_quoted(code)

  def parse({:ok, ast}),
    do: parse(ast, []) |> index()

  def parse({_, _, _} = ast, aliases),
    do: Parser.Triple.parse(ast, aliases)

  def parse({_, _} = ast, aliases),
    do: Parser.Tuple.parse(ast, aliases)

  def parse(ast, aliases) when is_list(ast),
    do: ast |> Enum.map(&parse(&1, aliases))

  def parse(ast, _aliases),
    do: Parser.Literal.parse(ast)

  defp index(modules) do
    [root_module(modules) | inner_modules(modules)]
    |> Enum.reduce(%{}, fn item, result ->
      Map.put(result, context(item), item)
    end)
  end

  defp root_module(modules),
    do: modules |> Enum.filter(&is_map/1)

  defp inner_modules(modules),
    do: modules |> Enum.filter(&is_list/1)

  defp context(module) do
    module
    |> Enum.flat_map(fn
      %{context: context} -> List.wrap(context)
      _ -> []
    end)
  end
end
