defmodule Umwelt.Parser.Defstruct do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Felixir.{Field, Literal, Value}
  alias Umwelt.Parser

  def combine(%{fields: fields} = concept, types) do
    Map.put(
      concept,
      :fields,
      add_types(fields, Parser.Struct.types(types, concept.aliases, concept.context))
    )
  end

  def parse({:defstruct, _, [{:@, _, [{name, _, nil}]}]}, _aliases, concept) do
    str_name = to_string(name)
    [attr] = Enum.filter(concept.attrs, &match?(%{name: ^str_name}, &1))

    %{
      defstruct: Enum.map(attr.value.elements, &parse_field(&1, concept.aliases, concept.context))
    }
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

  defp add_types(fields, types) do
    Enum.map(fields, fn %Field{name: field_name} = field ->
      case types[String.to_atom(field_name)] do
        nil -> field
        type -> Map.put(field, :type, type)
      end
    end)
  end
end
