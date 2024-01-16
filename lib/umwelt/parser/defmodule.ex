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
    |> parse_block(context ++ module)
    |> combine(%{
      body: to_string(List.last(module)),
      kind: :space,
      context: context ++ module
    })
    |> combine_functions()
    |> List.wrap()
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

  defp parse_block_child({:defmodule, _, _} = ast, context, _aliases) do
    parse(ast, context)
  end

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

  defp combine(block_children, module) do
    Enum.reduce([[module] | block_children], fn
      %{moduledoc: [value]}, [head | rest] ->
        [%{}, Map.put(head, :note, value) | rest]

      %{doc: [value]}, [head | rest] ->
        [Map.put(head, :note, value) | rest]

      %{impl: [value]}, [head | rest] ->
        [Map.put(head, :impl, value) | rest]

      %{kind: :function} = function, [head | rest] ->
        [%{}, Map.merge(head, function) | rest]

      inner_module, acc when is_list(inner_module) ->
        [inner_module | acc]
    end)
    |> Enum.reject(&Enum.empty?/1)
  end

  defp combine_functions(modules) do
    this_module =
      modules
      |> Enum.filter(&is_map(&1))
      |> Enum.reduce(%{}, fn
        %{kind: :space} = space, acc ->
          Map.merge(space, acc)

        %{kind: :function} = func, acc ->
          functions = acc[:functions] || []
          Map.put(acc, :functions, [func | functions])

          # other, acc ->
          #   IO.inspect(other, label: :combine_other)
          #   acc
      end)

    [this_module | Enum.filter(modules, &is_list(&1))]
  end
end
