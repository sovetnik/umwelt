defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: children |> parse_children(context)

  defp parse_children(
         [
           {:__aliases__, _, module},
           [do: block_children]
         ],
         context
       ) do
    block_children
    |> parse_block(module)
    |> combine(%{context: context ++ module})
  end

  defp parse_block({:defmodule, _, _} = ast, context),
    do: [parse(ast, context)]

  defp parse_block({:@, _, _} = ast, _context),
    do: [Parser.Attrs.parse(ast)]

  defp parse_block({:__block__, _, block_children}, context) do
    block_children
    |> Enum.map(&parse_block_child(&1, context, aliases(block_children)))
    |> Enum.reject(&is_nil(&1))
  end

  defp parse_block_child({:defmodule, _, _} = ast, context, _),
    do: parse(ast, context)

  defp parse_block_child({:@, _, _} = ast, _, _),
    do: Parser.Attrs.parse(ast)

  defp parse_block_child({:def, _, _} = ast, _, aliases),
    do: Parser.Def.parse(ast, aliases)

  defp parse_block_child(_ast, _context, _block_children),
    do: nil

  defp aliases(children) do
    children
    |> Enum.flat_map(fn
      {:alias, _, [{:__aliases__, _, module}]} ->
        [module]

      _other ->
        # other |> IO.inspect(label: :other_in_parse_aliases)
        []
    end)
  end

  defp combine(block_children, acc) do
    block_children
    |> Enum.reduce([acc], fn
      %{moduledoc: value}, [head | rest] ->
        head = head |> Map.put(:moduledoc, value)
        [%{}, head | rest]

      %{doc: value}, [head | rest] ->
        head = head |> Map.put(:doc, value)
        [head | rest]

      %{impl: value}, [head | rest] ->
        head = head |> Map.put(:impl, value)
        [head | rest]

      %{method: _} = child, [head | rest] ->
        head = head |> Map.merge(child)
        [%{}, head | rest]

      child, list when is_list(child) ->
        [%{}, child | list]

        # other, list ->
        #   other |> IO.inspect(label: :other_in_parse_block)
        #   list
    end)
    |> Enum.reject(&Enum.empty?/1)
  end
end
