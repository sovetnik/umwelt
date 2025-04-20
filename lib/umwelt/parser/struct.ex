defmodule Umwelt.Parser.Struct do
  @moduledoc "Indexes struct types in map"

  alias Umwelt.Felixir.Type
  alias Umwelt.Parser

  def types(types, aliases, context) do
    index = Enum.into(types, %{}, &{&1.name, &1.spec})

    index
    |> Map.get("t", [])
    |> index_struct_types(index, aliases, context)
  end

  defp index_struct_types(t_types, types, aliases, context),
    do: Enum.map(t_types, &build_type(&1, types, aliases, context))

  defp build_type({field_name, {_, _, _} = field}, types, aliases, context),
    do: {field_name, extract_struct_type(field, types, aliases, context)}

  # union type "Bar.t() | Baz.t()"
  defp extract_struct_type({:|, _, _} = ast, _types, aliases, context),
    do: Parser.parse(ast, aliases, context)

  # aliased call type "Baz.t()"
  defp extract_struct_type(
         {{:., _, [{:__aliases__, _, _}, :t]}, _, []} = ast,
         _,
         aliases,
         context
       ),
       do: Parser.parse(ast, aliases, context)

  # call type "word()" or  "word"
  defp extract_struct_type({term, _, _}, types, _aliases, _context) do
    case Map.get(types, to_string(term)) do
      nil -> Parser.Literal.type_of(term)
      type -> %Type{name: to_string(term), spec: type}
    end
  end
end
