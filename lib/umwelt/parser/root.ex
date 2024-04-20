defmodule Umwelt.Parser.Root do
  @moduledoc "Parses Root Module AST"

  alias Umwelt.Parser

  def parse({:defmodule, _meta, [{:__aliases__, _, module}, [do: block_children]]}),
    do: do_parse(block_children, module)

  defp do_parse(block_children, [module]) do
    block_children
    |> Parser.Defmodule.parse_block([module])
    |> Parser.Defmodule.combine(dummy(module, [module], :Root))
  end

  defp do_parse(block_children, module) do
    [this_module | rest] = Enum.reverse(module)

    append_dummy(rest, [
      block_children
      |> Parser.Defmodule.parse_block(module)
      |> Parser.Defmodule.combine(dummy(this_module, module, :Space))
    ])
  end

  defp append_dummy([module], block) do
    [dummy(module, [module], :Root) | block]
  end

  defp append_dummy([this_module | rest] = module, block) do
    append_dummy(rest, [[dummy(this_module, Enum.reverse(module), :Space) | block]])
  end

  defp dummy(this_module, context, kind) do
    %{
      body: to_string(this_module),
      kind: kind,
      context: context,
      attrs: [],
      functions: [],
      guards: []
    }
  end
end
