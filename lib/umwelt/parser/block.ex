defmodule Umwelt.Parser.Block do
  @moduledoc "Parses list of ASTs from block"

  @skip_terms ~w{ |> = alias defdelegate defimpl defmacro defmacrop if case }a
  @block_children ~w|def defp import require use defguard defmodule|a

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Parser

  def parse(block, aliases, context) do
    block
    |> children()
    |> Enum.map(&Parser.Macro.parse(&1, aliases, context))
  end

  def parse(block, context) do
    block
    |> children()
    |> Enum.map(&parse_child(&1, context))
    |> Enum.reject(&is_nil/1)
  end

  def children(block) do
    block
    |> wrap_block_children()
    |> unwrap_block_children()
  end

  defp parse_child({kind, _, _}, _)
       when kind in @skip_terms,
       do: nil

  defp parse_child({:@, _, _} = ast, concept),
    do: Parser.Attrs.parse(ast, concept.aliases, concept.context)

  defp parse_child({term, _, _} = ast, concept)
       when term in @block_children or is_macro(term),
       do: Parser.parse(ast, concept.aliases, concept.context)

  defp parse_child({:defstruct, _, _fields} = ast, concept),
    do: Parser.Defstruct.parse(ast, concept.aliases, concept)

  defp parse_child({_, _, _}, _), do: nil

  defp wrap_block_children({:__block__, _, block_children}),
    do: {:__block__, [], block_children}

  defp wrap_block_children(child),
    do: {:__block__, [], [child]}

  defp unwrap_block_children({:__block__, [], children}),
    do: children
end
