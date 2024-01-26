defmodule Umwelt.Parser.Root do
  @moduledoc "Parses Root Module AST"

  alias Umwelt.Parser

  def parse({:defmodule, _meta, [{:__aliases__, _, module}, [do: block_children]]}),
    do: do_parse(block_children, module)

  def do_parse(block_children, module) when length(module) == 1 do
    block_children
    |> Parser.Defmodule.parse_block(module)
    |> Parser.Defmodule.combine(%{
      body: to_string(List.last(module)),
      kind: :root,
      context: module,
      attrs: []
    })
  end

  # make it recursive for case Foo.Bar.Baz
  def do_parse(block_children, [head | _tail] = module) do
    [
      %{
        body: to_string(head),
        kind: :root,
        context: [head],
        functions: [],
        attrs: []
      }
      | [
          block_children
          |> Parser.Defmodule.parse_block(module)
          |> Parser.Defmodule.combine(%{
            body: to_string(List.last(module)),
            kind: :space,
            context: module,
            attrs: []
          })
        ]
    ]
  end
end
