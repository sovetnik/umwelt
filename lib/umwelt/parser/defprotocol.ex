defmodule Umwelt.Parser.Defprotocol do
  @moduledoc "Parses :defprotocol AST"

  # require Logger
  # @log_message "Unknown AST skipped in Defprotocol.parse."

  import Umwelt.Parser.Util, only: [string_or: 2]

  alias Umwelt.Felixir.{Protocol, Signature}
  alias Umwelt.Parser

  def parse({:defprotocol, _meta, children}, context),
    do: parse_children(children, [], context)

  defp parse_children([{:__aliases__, _, module}, [do: block]], _, context) do
    %Protocol{
      name: to_string(List.last(module)),
      note: extract_moduledoc(block, module),
      aliases: extract_aliases(block, context),
      context: (context ++ module) |> Enum.map(&to_string/1)
    }
    |> add_signatures(block)
  end

  defp add_signatures(proto, children) do
    signatures =
      children
      |> Parser.Block.parse(proto.aliases, proto.context)
      |> combine_signatures()

    Map.put(proto, :signatures, signatures)
  end

  defp combine_signatures(parsed) do
    Enum.reduce([[%Signature{}] | parsed], fn
      %{doc: [value]} = element, [head | rest]
      when not is_struct(element) ->
        [Map.put(head, :note, string_or(value, "fun description")) | rest]

      %{spec: value} = element, [head | rest]
      when not is_struct(element) ->
        [Map.put(head, :body, Parser.Types.specify(value, %{})) | rest]

      %Signature{} = sign, [head | rest] ->
        [%Signature{}, Signature.merge(sign, head) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}combine_signatures(/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&match?(%Signature{body: nil}, &1))
    |> Enum.reverse()
  end

  defp extract_moduledoc(children, module) do
    children
    |> Parser.Block.children()
    |> Enum.map(fn
      {:@, _, _} = ast -> Parser.Attrs.parse(ast, [], [])
      _ -> nil
    end)
    |> Enum.map(fn
      %{moduledoc: moduledoc} -> moduledoc
      _ -> "#{to_string(List.last(module))} protocol"
    end)
    |> Enum.reject(&is_nil/1)
    |> List.flatten()
    |> List.first()
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
