defmodule Umwelt.Parser.Attrs do
  @moduledoc "Parses @attr AST"

  require Logger
  @log_message "Unknown AST skipped in Attrs.parse"

  alias Umwelt.Felixir.Attribute
  alias Umwelt.Parser

  def parse({:@, _, [children]}, _aliases, context \\ []),
    do: parse_children(children, context)

  defp parse_children({term, _, _}, _context) when term in ~w|behaviour opaque typep|a,
    do: nil

  defp parse_children({term, _, value}, _context) when term in ~w|doc moduledoc|a,
    do: [{term, value}] |> Enum.into(%{})

  defp parse_children({term, _, _} = ast, context)
       when term in ~w|spec type|a,
       do: [{term, Parser.Typespec.parse(ast, [], context)}] |> Enum.into(%{})

  defp parse_children({:typedoc, _, value}, _context),
    do: %{typedoc: Parser.maybe_list_parse(value, [], [])}

  defp parse_children({:impl, _, value}, _context),
    do: %{impl: Parser.maybe_list_parse(value, [], [])}

  defp parse_children({constant, _, [child]}, _context),
    do: %Attribute{
      name: to_string(constant),
      value: Parser.parse(child, [], [])
    }

  defp parse_children(ast, _context) do
    Logger.warning("#{@log_message}_block/2\n #{inspect(ast)}")
    %{unknown: "unknown attr"}
  end
end
