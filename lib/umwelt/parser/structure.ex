defmodule Umwelt.Parser.Structure do
  @moduledoc "Parses %Structure{} and <<>> AST"

  alias Umwelt.Felixir.{Structure, Variable}
  alias Umwelt.Parser

  defguard is_structure(term) when term in [:%, :%{}, :<<>>, :{}]

  def parse({:%, _, [{:__aliases__, _, _} = ast, {:%{}, _, children}]}, aliases, context),
    do: %Structure{
      type: Parser.parse(ast, aliases, context),
      elements: Parser.parse_list(children, aliases, context)
    }

  def parse({:%, _, [{:__MODULE__, _, nil}, {:%{}, _, children}]}, aliases, context),
    do: %Structure{
      type: aliases,
      elements: Parser.parse_list(children, aliases, context)
    }

  def parse({:%, _, [{term, _, nil}, {:%{}, _, children}]}, aliases, context),
    do: %Structure{
      type: %Variable{body: to_string(term), type: Parser.Literal.type_of(:atom)},
      elements: Parser.parse_list(children, aliases, context)
    }

  def parse({:%{}, _, children}, aliases, context),
    do: %Structure{
      type: Parser.Literal.type_of(:map),
      elements: Parser.parse_list(children, aliases, context)
    }

  def parse({:<<>>, _, children}, aliases, context) do
    literal_bits =
      children
      |> Enum.reject(&match?({_, _, _}, &1))
      |> Parser.maybe_list_parse(aliases, context)

    %Structure{
      type: Parser.Literal.type_of(:bitstring),
      elements: literal_bits
    }
  end

  def parse({:{}, _, children}, aliases, context),
    do: %Structure{
      type: Parser.Literal.type_of(:tuple),
      elements: Parser.parse_list(children, aliases, context)
    }

  def parse(tuple, aliases, context) when is_tuple(tuple),
    do: %Structure{
      type: Parser.Literal.type_of(:tuple),
      elements: tuple |> Tuple.to_list() |> Parser.parse_list(aliases, context)
    }
end
