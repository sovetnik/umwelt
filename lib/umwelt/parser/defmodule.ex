defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  require Logger
  @log_message "Unknown AST skipped in Defmodule."
  @skip_terms ~w{ |> = alias defdelegate defimpl defmacro defmacrop if case }a

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Felixir.Concept
  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, [], context)

  defp parse_children([{:__aliases__, _, module}, [do: block_children]], _, context) do
    path = (context ++ module) |> Enum.map(&to_string/1)

    block_children
    |> wrap_block_children()
    |> parse_block(path)
    |> Parser.Root.combine(%Concept{
      aliases: extract_aliases(block_children, context),
      name: to_string(List.last(module)),
      context: path
    })
  end

  def extract_aliases({:__block__, _, block_children}, context) do
    block_children
    |> Enum.map(fn
      {:alias, _, _} = ast -> extract_aliases(ast, context)
      _ -> nil
    end)
    |> Enum.reject(&is_nil(&1))
    |> List.flatten()
  end

  def extract_aliases({:alias, _, _} = ast, context), do: Parser.Aliases.parse(ast, [], context)

  def extract_aliases(_, _), do: []

  def parse_block({:__block__, _, block_children}, context) do
    block_children
    |> Enum.map(&parse_block_child(&1, aliases(block_children, context), context))
    |> Enum.reject(&is_nil(&1))
  end

  def parse_block({:@, _, _} = ast, context),
    do: Parser.Attrs.parse(ast, [], context)

  def parse_block({term, _, _} = ast, context)
      when term in [:@, :defguard, :defmodule, :defstruct],
      do: [Parser.parse(ast, [], context)]

  def parse_block(ast, _) do
    Logger.warning("#{@log_message}parse_block/2\n #{inspect(ast)}")
    []
  end

  defp wrap_block_children({:__block__, _, block_children}),
    do: {:__block__, [], block_children}

  defp wrap_block_children(child),
    do: {:__block__, [], [child]}

  defp parse_block_child({:alias, _, _}, _, _), do: nil

  defp parse_block_child({kind, _, _}, _, _)
       when kind in @skip_terms,
       do: nil

  defp parse_block_child({:@, _, _} = ast, aliases, context),
    do: Parser.Attrs.parse(ast, aliases, context)

  defp parse_block_child({term, _, _} = ast, aliases, context)
       when is_macro(term),
       do: Parser.parse(ast, aliases, context)

  defp parse_block_child({term, _, _} = ast, aliases, context)
       when term in ~w|def defp import require use defguard defmodule|a,
       do: Parser.parse(ast, aliases, context)

  defp parse_block_child({:defstruct, _, _fields} = ast, aliases, context),
    do: Parser.Defstruct.parse(ast, aliases, context)

  defp aliases(children, context) do
    Enum.flat_map(children, fn
      {:alias, _, _} = ast -> Parser.Aliases.parse(ast, [], context) |> List.wrap()
      _other -> []
    end)
  end
end
