defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  # require Logger
  # @log_message "Unknown AST skipped in Defmodule."

  alias Umwelt.Felixir.{Attribute, Concept}
  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, [], context)

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
      %Attribute{} = value, %{attrs: attrs} = concept ->
        Map.put(concept, :attrs, [value | attrs])

      _other, concept ->
        # Logger.warning("#{@log_message}combine/2\n #{inspect(other, pretty: true)}")
        concept
    end)
  end

  def extract_aliases({:__block__, _, block}, context) do
    # alias Foo.{ Bar, Baz } => [~Bar, ~Baz]
    # compact alias clause produces list
    block
    |> Enum.map(fn
      {:alias, _, _} = ast -> extract_aliases(ast, context)
      _other -> nil
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  def extract_aliases({:alias, _, _} = ast, context),
    do: Parser.Aliases.parse(ast, [], context)

  def extract_aliases(_, _), do: []
end
