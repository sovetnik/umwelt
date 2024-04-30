defmodule Umwelt.Parser.Defstruct do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Parser

  def parse({:defstruct, _meta, [fields]}, aliases),
    do: %{defstruct: parse_children(fields, aliases)}

  defp parse_children(fields, aliases),
    do: Enum.map(fields, &parse_field(&1, aliases))

  def parse_field({field, value}, aliases) do
    %{
      body: to_string(field),
      kind: :Field,
      type: %{kind: :Literal, type: :anything},
      value: Parser.parse(value, aliases)
    }
  end
end
