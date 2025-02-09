defmodule Umwelt.Parser.Defstruct do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Felixir.{Field, Literal}
  alias Umwelt.Parser

  def parse({:defstruct, _meta, [fields]}, aliases, context),
    do: %{defstruct: Enum.map(fields, &parse_field(&1, aliases, context))}

  def combine(%{fields: fields} = concept, types, aliases, context),
    do: Map.put(concept, :fields, add_types(fields, Parser.Struct.types(types, aliases, context)))

  defp parse_field(field, aliases, context) when is_atom(field),
    do: %Field{
      name: to_string(field),
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
