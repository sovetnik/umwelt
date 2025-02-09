defmodule Umwelt.Parser do
  @moduledoc "Extracts metadata from AST"

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Felixir.Structure
  alias Umwelt.{Files, Parser}

  def parse_raw(code) do
    case read_ast({:ok, code}) do
      {:ok, ast} ->
        parse_ast({:ok, ast})

      {:error, message} ->
        {:error, message}
    end
  end

  def parse_source(project) do
    Map.merge(
      parse_root_source(project),
      parse_other_sources(project)
    )
  end

  def read_ast({:ok, code}), do: Code.string_to_quoted(code)
  def read_ast({:error, msg}), do: {:error, msg}
  def read_ast(code) when is_binary(code), do: read_ast({:ok, code})

  def parse_root({:ok, ast}),
    do: ast |> Parser.Root.parse() |> index()

  # AST of blanc file
  def parse_ast({:ok, {:__block__, [line: 1], []}}),
    do: %{[] => %{}}

  # AST of good file
  def parse_ast({:ok, ast}),
    do: ast |> parse([], []) |> index()

  # AST of wrong file
  def parse_ast({:error, _}),
    do: %{[] => %{}}

  def parse(ast, aliases, context) when is_macro(ast),
    do: Parser.Macro.parse(ast, aliases, context)

  def parse({_, _} = ast, aliases, context),
    do: Parser.Structure.parse(ast, aliases, context)

  def parse(ast, aliases, context) when is_list(ast),
    do: %Structure{
      type: Parser.Literal.type_of(:list),
      elements: parse_list(ast, aliases, context)
    }

  def parse(ast, _aliases, _context),
    do: Parser.Literal.parse(ast)

  def maybe_list_parse(ast, aliases, context) when is_list(ast),
    do: parse_list(ast, aliases, context)

  def maybe_list_parse(ast, aliases, context),
    do: parse(ast, aliases, context)

  def parse_list(ast, aliases, context) when is_list(ast),
    do: Enum.map(ast, &parse(&1, aliases, context))

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
    |> read_ast()
    |> parse_root()
  end

  defp parse_other_sources(project) do
    project
    |> Files.list_root_dir()
    |> Enum.map(
      &(&1
        |> File.read()
        |> read_ast()
        |> parse_ast())
    )
    |> Enum.reduce(&Map.merge/2)
  end
end
