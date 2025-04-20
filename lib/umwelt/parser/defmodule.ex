defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  # require Logger
  # @log_message "Unknown AST skipped in Defmodule."

  alias Umwelt.Felixir.{Attribute, Concept}
  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, [], context) |> List.wrap()

  defp parse_children([{:__aliases__, _, module}, [do: block]], _, context) do
    concept =
      %Concept{
        aliases: extract_aliases(block, context),
        name: to_string(List.last(module)),
        context: (context ++ module) |> Enum.map(&to_string/1)
      }

    block
    |> Parser.Block.parse(add_attributes(concept, block))
    |> Parser.Root.combine(concept)
  end

  def add_attributes(concept, block) do
    block
    |> Parser.Block.children()
    |> Enum.map(fn
      {:@, _, _} = ast -> Parser.Attrs.parse(ast, concept.aliases, concept.context)
      _ -> nil
    end)
    |> List.flatten()
    |> Enum.reduce(concept, fn
      %Attribute{} = value, %{attrs: attrs} = concept -> Map.put(concept, :attrs, [value | attrs])
      _other, concept -> concept
    end)
  end

  # alias Foo.{ Bar, Baz } => [~Bar, ~Baz]
  # as compact alias clause produces list
  def extract_aliases({:__block__, _, block}, context) do
    block
    |> Enum.map(fn
      {:alias, _, _} = ast -> extract_aliases(ast, context)
      _other -> []
    end)
    |> List.flatten()
  end

  def extract_aliases({:alias, _, _} = ast, context), do: Parser.Aliases.parse(ast, [], context)
  def extract_aliases(_, _), do: []
end
