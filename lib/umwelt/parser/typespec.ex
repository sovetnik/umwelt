defmodule Umwelt.Parser.Typespec do
  @moduledoc "Parses Typespec definition AST"

  alias Umwelt.Felixir.{Call, Type, Variable}
  alias Umwelt.Parser

  import Umwelt.Parser.Literal, only: [is_literal: 1]

  def parse({:|, _, _} = ast, aliases, context),
    do: Parser.parse(ast, aliases, context)

  def parse({:type, _, [value]}, aliases, context),
    do: Parser.parse(value, aliases, context)

  def parse({:spec, _, [value]}, aliases, context),
    do: parse(value, aliases, context)

  def parse({:@, _, [{term, _, [{:"::", _, [left, right]}]}]}, aliases, context),
    do: parse([{term, [], [left, right]}], aliases, context)

  def parse({{:., _, [{:__aliases__, _, _}, _]}, _, []} = ast, aliases, context),
    do: Parser.parse(ast, aliases, context)

  def parse({term, _, []}, _aliases, _context)
      when is_atom(term) and is_literal(term),
      do: Parser.Literal.type_of(term)

  def parse({term, _, nil}, _aliases, _context)
      when is_atom(term) and is_literal(term),
      do: Parser.Literal.type_of(term)

  def parse({:"::", _, [left, {type, _, nil}]}, aliases, context) do
    left
    |> Parser.parse(aliases, context)
    |> Map.put(:type, Parser.Literal.type_of(type))
  end

  def parse({:"::", _, [left, right]}, aliases, context) do
    left
    |> spec(aliases, context)
    |> Map.put(:type, parse(right, aliases, context))
  end

  # because here we don't have all parsed types yet,
  # we pass the raw types of map fields
  def parse({:%, _, children}, _aliases, context) do
    atomic_context = Enum.map(context, &String.to_atom/1)

    case children do
      [{:__MODULE__, _, nil}, {:%{}, _, types}] -> types
      [{:__aliases__, _, ^atomic_context}, {:%{}, _, types}] -> types
    end
  end

  def parse([{:spec, _, [left, right]}], aliases, context),
    do: %{
      spec:
        left
        |> Parser.parse(aliases, context)
        |> Map.put(:type, parse(right, aliases, context))
    }

  def parse([{:type, _, [left, right]}], aliases, context),
    do: %Type{
      name: Parser.parse(left, aliases, context) |> name(),
      spec: spec(right, [], [])
    }

  def parse(term, aliases, context) when is_atom(term),
    do: Parser.parse(term, aliases, context)

  defp name(%Call{name: name}), do: name
  defp name(%Variable{body: name}), do: name

  defp spec({term, _, nil}, _aliases, _context)
       when is_literal(term),
       do: Parser.Literal.type_of(term)

  defp spec({term, _, []}, _aliases, _context)
       when is_literal(term),
       do: Parser.Literal.type_of(term)

  defp spec(ast, aliases, context),
    do: Parser.parse(ast, aliases, context)
end
