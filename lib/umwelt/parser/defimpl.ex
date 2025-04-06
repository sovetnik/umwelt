defmodule Umwelt.Parser.Defimpl do
  @moduledoc "Parses :defimpl AST"

  # require Logger
  # @log_message "Unknown AST skipped in Defprotocol.parse."

  import Umwelt.Parser.Util, only: [string_or: 2]

  alias Umwelt.Felixir.{Function, Implement}
  alias Umwelt.Parser

  def parse({:defimpl, _meta, implement}, aliases, context),
    do: [parse_implement(implement, aliases, context)]

  defp parse_implement([proto, [for: subject], [do: block]], aliases, context) do
    proto_alias = Parser.Aliases.parse_impl(proto, aliases, context)
    subject_alias = Parser.Aliases.parse_impl(subject, aliases, context)

    %Implement{
      name: proto_alias.name,
      note: "impl #{proto_alias.name} for #{subject_alias.name}",
      aliases: extract_aliases(block, context),
      context: subject_alias.path ++ [proto_alias.name],
      protocol: proto_alias,
      subject: subject_alias
    }
    |> add_functions(block)
  end

  defp add_functions(implement, children) do
    functions =
      children
      |> Parser.Block.parse(implement.aliases, implement.protocol)
      |> combine_functions()
      |> Enum.map(&add_type_to_first_arg(&1, implement.subject))

    Map.put(implement, :functions, functions)
  end

  defp add_type_to_first_arg(%{body: %{arguments: [var | args]}} = function, subj),
    do: put_in(function.body.arguments, [Map.put(var, :type, subj) | args])

  defp combine_functions(parsed) do
    Enum.reduce([[%Function{}] | parsed], fn
      %{doc: [value]}, [head | rest] ->
        [Map.put(head, :note, string_or(value, "fun description")) | rest]

      %Function{} = fun, [head | rest] ->
        [%Function{}, Function.merge(fun, head) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}combine_functions(/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&match?(%Function{body: nil}, &1))
    |> Enum.map(&Map.put(&1, :impl, true))
    |> Enum.reverse()
  end

  defp extract_aliases(block, context) do
    block
    |> Parser.Block.children()
    |> Enum.flat_map(fn
      {:alias, _, _} = ast -> Parser.Aliases.parse(ast, [], context) |> List.wrap()
      _other -> []
    end)
    |> Enum.reject(&is_nil/1)
  end
end
