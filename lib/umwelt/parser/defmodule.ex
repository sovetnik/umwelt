defmodule Umwelt.Parser.Defmodule do
  @moduledoc "Parses Module AST"

  require Logger
  @log_message "Unknown AST skipped in Defmodule."

  @skip_terms ~w{ |> = alias defdelegate defimpl defmacro defmacrop if case }a

  import Umwelt.Parser.Macro, only: [is_macro: 1]

  alias Umwelt.Parser

  def parse({:defmodule, _meta, children}, context),
    do: parse_children(children, context)

  defp parse_children(
         [{:__aliases__, _, module}, [do: block_children]],
         context
       ) do
    path =
      (context ++ module)
      |> Enum.map(&to_string/1)

    block_children
    |> parse_block(path)
    |> combine(%{
      body: to_string(List.last(module)),
      attrs: [],
      calls: [],
      guards: [],
      types: [],
      kind: :Concept,
      context: path
    })
  end

  def parse_block({:__block__, _, block_children}, context) do
    block_children
    |> Enum.map(&parse_block_child(&1, context, aliases(block_children)))
    |> Enum.reject(&is_nil(&1))
  end

  def parse_block({:@, _, _} = ast, context),
    do: Parser.Attrs.parse(ast, context)

  def parse_block({term, _, block_children} = ast, _context)
      when term in ~w|def import require use|a,
      do: [Parser.parse(ast, aliases(block_children))]

  def parse_block({term, _, _} = ast, context)
      when term in [:@, :defguard, :defmodule, :defstruct],
      do: [Parser.parse(ast, context)]

  def parse_block(ast, _) do
    Logger.warning("#{@log_message}parse_block/2\n #{inspect(ast)}")
    []
  end

  defp parse_block_child({:@, _, _} = ast, _, _),
    do: Parser.Attrs.parse(ast)

  defp parse_block_child({:alias, _, _}, _, _), do: nil

  defp parse_block_child({term, _, _} = ast, _, aliases)
       when is_macro(term),
       do: Parser.parse(ast, aliases)

  defp parse_block_child({term, _, _} = ast, _, aliases)
       when term in ~w|def defp import require use|a,
       do: Parser.parse(ast, aliases)

  defp parse_block_child({term, _, _} = ast, context, _aliases)
       when term in ~w|defguard defmodule|a,
       do: Parser.parse(ast, context)

  defp parse_block_child({:defstruct, _, fields}, _context, aliases) do
    Parser.parse({:defstruct, [], fields}, aliases)
  end

  defp parse_block_child({kind, _, _}, _, _) when kind in @skip_terms, do: []

  defp parse_block_child(ast, _, _) do
    Logger.warning("#{@log_message}parse_block_child/3\n #{inspect(ast)}")
    nil
  end

  defp aliases(children) do
    Enum.flat_map(children, fn
      {:alias, _, _} = ast ->
        Parser.Aliases.parse(ast, [])
        |> List.wrap()

      _other ->
        []
    end)
  end

  def combine(block_children, module) do
    this_module =
      block_children
      |> combine_module(module)
      |> Map.put(:functions, extract_functions(block_children))
      |> Map.put(:types, extract_types(block_children))

    [this_module | Enum.filter(block_children, &is_list(&1))]
  end

  defp combine_module(block_children, module) when is_list(block_children) do
    Enum.reduce(block_children, module, fn
      %{moduledoc: [value]}, module ->
        Map.put(module, :note, string_or(value, "Description of #{module.body}"))

      %{defstruct: fields}, module ->
        Map.put(module, :fields, fields)

      %{defguard: value}, %{guards: attrs} = module ->
        Map.put(module, :guards, [value | attrs])

      %{kind: :Attr} = value, %{attrs: attrs} = module ->
        Map.put(module, :attrs, [value | attrs])

      %{kind: :Call} = value, %{calls: calls} = module ->
        Map.put(module, :calls, [value | calls])

      # doc and impl related to function and parsed in functions
      %{typedoc: _}, module ->
        module

      %{doc: _}, module ->
        module

      %{impl: _}, module ->
        module

      %{spec: _}, module ->
        module

      %{typep: _}, module ->
        module

      %{type: %{kind: kind}}, module
      when kind in [:Call, :Variable] ->
        module

      %{kind: kind}, module
      when kind in [:Call, :Function, :Operator, :PrivateFunction] ->
        module

      children, module when is_list(children) ->
        module

      other, module ->
        Logger.warning("#{@log_message}combine_module/2\n #{inspect(other, pretty: true)}")
        module
    end)
  end

  defp combine_module(block_children, module) do
    combine_module([block_children], module)
  end

  defp extract_functions(block_children) do
    Enum.reduce([[%{}] | block_children], fn
      %{doc: [value]}, [head | rest] ->
        [Map.put(head, :note, string_or(value, "fun description")) | rest]

      %{spec: value}, [head | rest] ->
        [Map.put(head, :spec, value) | rest]

      %{impl: [value]}, [head | rest] ->
        [Map.put(head, :impl, value) | rest]

      %{kind: :Function} = function, [head | rest] ->
        [%{}, Map.merge(head, function) | rest]

      %{kind: :PrivateFunction}, [_head | rest] ->
        [%{} | rest]

      %{kind: :Operator, body: "when"} = function, [head | rest] ->
        [%{}, Map.merge(head, function) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}_extract_functions/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.reverse()
  end

  defp extract_types(block_children) do
    Enum.reduce([[%{}] | block_children], fn
      %{typedoc: [%{type: %{kind: :Literal, type: :binary}, body: body, kind: :Value}]},
      [head | rest] ->
        [Map.put(head, :note, string_or(body, "Description of type")) | rest]

      %{typedoc: value}, [head | rest] ->
        [Map.put(head, :note, string_or(value, "Description of type")) | rest]

      %{type: value}, [head | rest] ->
        [%{}, Map.merge(head, value) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}_extract_types/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.reverse()
  end

  defp string_or(value, replace) do
    case value do
      value when is_binary(value) ->
        string =
          value
          |> String.split("\n")
          |> List.first()

        if String.length(string) < 255 do
          string
        else
          replace
        end

      _ ->
        replace
    end
  end
end
