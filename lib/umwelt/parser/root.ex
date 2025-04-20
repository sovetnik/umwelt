defmodule Umwelt.Parser.Root do
  @moduledoc "Parses Root Module AST"

  alias Umwelt.Felixir.{Concept, Root, Type}
  alias Umwelt.Parser

  def combine(block, module) do
    types = Parser.Types.extract(block, module.aliases)

    this_module =
      block
      |> Concept.combine(module, types)
      |> Map.put(:functions, Parser.Functions.combine(block, types))
      |> Map.put(:types, Enum.reject(types, &match?(%Type{name: "t"}, &1)))

    [this_module | Enum.filter(block, &is_list/1)]
  end

  def parse({:defmodule, _meta, [{:__aliases__, _, module}, [do: block]]}),
    do: do_parse(block, module)

  defp do_parse(block, [module]) do
    block
    |> Parser.Block.parse(root(module, [module]))
    |> combine(root(module, [module]))
  end

  defp do_parse(block, module) do
    [this_module | rest] = Enum.reverse(module)

    append_dummy(rest, [
      block
      |> Parser.Block.parse(concept(this_module, module))
      |> combine(concept(this_module, module))
    ])
  end

  defp append_dummy([module], block), do: [root(module, [module]) | block]

  defp append_dummy([this_module | rest] = module, block),
    do: append_dummy(rest, [[concept(this_module, Enum.reverse(module)) | block]])

  defp root(this_module, context),
    do: %Root{
      name: to_string(this_module),
      context: Enum.map(context, &to_string/1)
    }

  defp concept(this_module, context),
    do: %Concept{
      name: to_string(this_module),
      context: Enum.map(context, &to_string/1)
    }
end
