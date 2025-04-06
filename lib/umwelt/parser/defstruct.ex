defmodule Umwelt.Parser.Defstruct do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Felixir.{Field, Literal, Value}
  alias Umwelt.Parser

  def parse({:defstruct, _, [{:@, _, [{name, _, nil}]}]}, _aliases, concept) do
    str_name = to_string(name)

    [%{value: %{elements: elements}}] =
      Enum.filter(concept.attrs, &match?(%{name: ^str_name}, &1))

    %{defstruct: Enum.map(elements, &parse_field(&1, concept.aliases, concept.context))}
  end

  def parse({:defstruct, _, [fields]}, aliases, context),
    do: %{defstruct: Enum.map(fields, &parse_field(&1, aliases, context))}

  defp parse_field(field, aliases, context) when is_atom(field),
    do: %Field{
      name: to_string(field),
      type: %Literal{type: :anything},
      value: Parser.parse(nil, aliases, context)
    }

  defp parse_field(%Value{body: body}, aliases, context),
    do: %Field{
      name: body,
      type: %Literal{type: :anything},
      value: Parser.parse(nil, aliases, context)
    }

  defp parse_field({field, value}, aliases, context),
    do: %Field{
      name: to_string(field),
      type: %Literal{type: :anything},
      value: Parser.parse(value, aliases, context)
    }
end
