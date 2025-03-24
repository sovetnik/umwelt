defmodule Umwelt.Parser do
  @moduledoc "Extracts metadata from AST"

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Felixir.Structure
  alias Umwelt.{Files, Parser}

  def parse_raw(code) do
    with {:ok, ast} <- read_ast(code) do
      parse_ast({:ok, ast}) |> index_deep()
    end
  end

  def read_ast({:ok, code}), do: Code.string_to_quoted(code)
  def read_ast({:error, msg}), do: {:error, msg}
  def read_ast(code) when is_binary(code), do: read_ast({:ok, code})

  # AST of wrong file
  def parse_ast({:error, _}), do: %{[] => %{}}

  # AST of blanc file
  def parse_ast({:ok, {:__block__, _, []}}), do: %{[] => %{}}

  def parse_ast({:ok, {:__block__, _, _} = block}),
    do: Parser.Block.parse(block, [], [])

  # AST of good file
  def parse_ast({:ok, ast}), do: ast |> parse([], [])

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

  def parse_root({:ok, ast}),
    do: ast |> Parser.Root.parse()

  def parse_source(project),
    do: Map.merge(parse_root_source(project), parse_other_sources(project))

  defp parse_root_source(project) do
    project
    |> Files.root_module()
    |> File.read()
    |> read_ast()
    |> parse_root()
    |> index_deep()
  end

  defp parse_other_sources(project) do
    project
    |> Files.list_root_dir()
    |> Enum.flat_map(&(&1 |> File.read() |> read_ast() |> parse_ast()))
    |> index_deep()
  end

  def index_deep(parsed) do
    parsed
    |> Enum.filter(&is_list/1)
    |> Enum.map(&index_deep(&1))
    |> Enum.reduce(index_root(parsed), &Map.merge/2)
  end

  def index_root(parsed) do
    parsed
    |> Enum.filter(&is_map/1)
    |> Map.new(&{&1.context, &1})
  end
end
