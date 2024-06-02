defmodule Umwelt.Parser do
  @moduledoc "Extracts metadata from AST"

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.{Files, Parser}

  def parse_source(project) do
    Map.merge(
      parse_root_source(project),
      parse_other_sources(project)
    )
  end

  def read_ast({:error, msg}), do: {:error, msg}

  def read_ast({:ok, code}),
    do: Code.string_to_quoted(code)

  def maybe_list_parse(ast, aliases) when is_list(ast),
    do: parse_list(ast, aliases)

  def maybe_list_parse(ast, aliases),
    do: parse(ast, aliases)

  def parse_list(ast, aliases) when is_list(ast),
    do: Enum.map(ast, &parse(&1, aliases))

  def parse({:ok, ast}),
    do: ast |> parse([]) |> index()

  def parse_root({:ok, ast}),
    do: ast |> Parser.Root.parse() |> index()

  def parse(ast, aliases) when is_macro(ast),
    do: Parser.Macro.parse(ast, aliases)

  def parse({_, _} = ast, aliases),
    do: Parser.Tuple.parse(ast, aliases)

  def parse(ast, aliases) when is_list(ast),
    do: %{
      kind: :Value,
      type: %{kind: :Structure, type: :list},
      values: parse_list(ast, aliases)
    }

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
      %{context: context} ->
        List.wrap(context)
        # _ -> []
    end)
  end

  defp parse_root_source(project) do
    project
    |> Files.root_module()
    |> File.read()
    |> Parser.read_ast()
    |> Parser.parse_root()
  end

  defp parse_other_sources(project) do
    project
    |> Files.list_root_dir()
    |> Enum.map(&(&1 |> File.read() |> Parser.read_ast() |> Parser.parse()))
    |> Enum.reduce(&Map.merge/2)
  end
end
