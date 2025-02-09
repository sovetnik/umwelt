defmodule Umwelt.Parser.Root do
  @moduledoc "Parses Root Module AST"

  alias Umwelt.Felixir.{Concept, Root, Type}
  alias Umwelt.Parser

  def parse({:defmodule, _meta, [{:__aliases__, _, module}, [do: block_children]]}),
    do: do_parse(block_children, module)

  def combine(block_children, concept) do
    types = Parser.Types.extract(block_children)

    this_concept =
      block_children
      |> Concept.combine(concept)
      |> Map.put(:functions, Parser.Functions.combine(block_children, types))
      |> Map.put(:types, Enum.reject(types, &match?(%Type{name: "t"}, &1)))
      |> Parser.Defstruct.combine(types, concept.aliases, concept.context)

    [this_concept | Enum.filter(block_children, &is_list(&1))]
  end

  defp do_parse(block_children, [module]) do
    block_children
    |> Parser.Defmodule.parse_block([module])
    |> combine(root(module, [module]))
  end

  defp do_parse(block_children, module) do
    [this_module | rest] = Enum.reverse(module)

    append_dummy(rest, [
      block_children
      |> Parser.Defmodule.parse_block(module)
      |> combine(concept(this_module, module))
    ])
  end

  defp append_dummy([module], block), do: [root(module, [module]) | block]

  defp append_dummy([this_module | rest] = module, block),
    do: append_dummy(rest, [[concept(this_module, Enum.reverse(module)) | block]])

  defp root(this_module, context),
    do: %Root{name: to_string(this_module), context: Enum.map(context, &to_string/1)}

  defp concept(this_module, context),
    do: %Concept{name: to_string(this_module), context: Enum.map(context, &to_string/1)}
end
