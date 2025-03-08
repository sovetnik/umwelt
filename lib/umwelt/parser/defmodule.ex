defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  require Logger
  @log_message "Unknown AST skipped in Defmodule."
  @skip_terms ~w{ |> = alias defdelegate defimpl defmacro defmacrop defprotocol if case }a

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Felixir.{Attribute, Concept}
  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, [], context)

  defp parse_children([{:__aliases__, _, module}, [do: block_children]], _, context) do
    concept =
      %Concept{
        aliases: extract_aliases(block_children, context),
        name: to_string(List.last(module)),
        context: (context ++ module) |> Enum.map(&to_string/1)
      }
      |> add_attributes(block_children)

    block_children
    |> wrap_block_children()
    |> parse_block(concept)
    |> Parser.Root.combine(Map.put(concept, :attrs, []))
  end

  def add_attributes(concept, {:__block__, _, block_children}) do
    block_children
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

  def add_attributes(concept, block_children),
    do: add_attributes(concept, wrap_block_children(block_children))

  def parse_block({:__block__, _, block_children}, concept) do
    block_children
    |> Enum.map(&parse_block_child(&1, concept))
    |> Enum.reject(&is_nil(&1))
  end

  def parse_block({:@, _, _} = ast, concept),
    do: Parser.Attrs.parse(ast, [], concept)

  def parse_block({term, _, _} = ast, concept)
      when term in [:defguard, :defmodule, :defstruct] do
    [Parser.parse(ast, [], concept.context)]
  end

  def parse_block(ast, _) do
    Logger.warning("#{@log_message}parse_block/2\n #{inspect(ast)}")
    []
  end

  defp wrap_block_children({:__block__, _, block_children}),
    do: {:__block__, [], block_children}

  defp wrap_block_children(child),
    do: {:__block__, [], [child]}

  defp parse_block_child({:alias, _, _}, _), do: nil

  defp parse_block_child({kind, _, _}, _)
       when kind in @skip_terms,
       do: nil

  defp parse_block_child({:@, _, _} = ast, concept),
    do: Parser.Attrs.parse(ast, concept.aliases, concept.context)

  defp parse_block_child({term, _, _} = ast, concept)
       when is_macro(term),
       do: Parser.parse(ast, concept.aliases, concept.context)

  defp parse_block_child({term, _, _} = ast, concept)
       when term in ~w|def defp import require use defguard defmodule|a,
       do: Parser.parse(ast, concept.aliases, concept.context)

  defp parse_block_child({:defstruct, _, _fields} = ast, concept),
    do: Parser.Defstruct.parse(ast, concept.aliases, concept)

  defp parse_block_child({_, _, _}, _), do: nil

  def extract_aliases({:__block__, _, block_children}, context) do
    block_children
    |> aliases(context)
    |> Enum.reject(&is_nil(&1))

    # |> List.flatten()
  end

  def extract_aliases({:alias, _, _} = ast, context), do: Parser.Aliases.parse(ast, [], context)

  def extract_aliases(_, _), do: []

  defp aliases(children, context) do
    Enum.flat_map(children, fn
      {:alias, _, _} = ast -> Parser.Aliases.parse(ast, [], context) |> List.wrap()
      _other -> []
    end)
  end
end
