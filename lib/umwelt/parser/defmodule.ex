defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, context)

  defp parse_children(
         [{:__aliases__, _, module}, [do: block_children]],
         context
       ) do
    block_children
    |> parse_block(context ++ module)
    |> combine(%{
      body: to_string(List.last(module)),
      attrs: [],
      guards: [],
      kind: :Space,
      context: context ++ module
    })
  end

  def parse_block({:__block__, _, block_children}, context) do
    block_children
    |> Enum.map(&parse_block_child(&1, context, aliases(block_children)))
    |> Enum.reject(&is_nil(&1))
  end

  def parse_block({term, _, _} = ast, context)
      when term in [:@, :defguard, :defmodule],
      do: [Parser.parse(ast, context)]

  defp parse_block_child({:@, _, _} = ast, _, _),
    do: Parser.parse(ast, [])

  defp parse_block_child({:def, _, _} = ast, _, aliases),
    do: Parser.parse(ast, aliases)

  defp parse_block_child({:defguard, _, _} = ast, context, _aliases),
    do: Parser.parse(ast, context)

  defp parse_block_child({:defmodule, _, _} = ast, context, _aliases),
    do: Parser.parse(ast, context)

  defp parse_block_child({:defstruct, _, fields}, _context, aliases) do
    Parser.parse({:defstruct, [], fields}, aliases)
  end

  defp parse_block_child(_ast, _, _), do: nil

  defp aliases(children) do
    Enum.flat_map(children, fn
      {:alias, _, _} = ast ->
        Parser.Aliases.parse(ast, [])

      _other ->
        []
    end)
  end

  def combine(block_children, module) do
    this_module =
      block_children
      |> combine_module(module)
      |> Map.put(:functions, extract_functions(block_children))

    [this_module | Enum.filter(block_children, &is_list(&1))]
  end

  defp combine_module(block_children, module) do
    Enum.reduce(block_children, module, fn
      %{moduledoc: [value]}, module ->
        Map.put(module, :note, value)

      %{defstruct: fields}, module ->
        Map.put(module, :fields, fields)

      %{defguard: value}, %{guards: attrs} = module ->
        Map.put(module, :guards, [value | attrs])

      %{kind: :Attr} = value, %{attrs: attrs} = module ->
        Map.put(module, :attrs, [value | attrs])

      _other, module ->
        module
    end)
  end

  defp extract_functions(block_children) do
    Enum.reduce([[%{}] | block_children], fn
      %{doc: [value]}, [head | rest] ->
        [Map.put(head, :note, value) | rest]

      %{impl: [value]}, [head | rest] ->
        [Map.put(head, :impl, value) | rest]

      %{kind: :Call} = function, [head | rest] ->
        [%{}, Map.merge(head, function) | rest]

      %{kind: :Operator, body: "when"} = function, [head | rest] ->
        [%{}, Map.merge(head, function) | rest]

      _other, acc ->
        acc
    end)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.reverse()
  end
end
