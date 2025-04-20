defmodule Umwelt.Parser.Signature do
  @moduledoc "Parses Function AST"

  alias Umwelt.Felixir.{Call, Signature}
  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({type, _, [function]}, aliases, context)
      when is_atom_macro(function),
      do: %Signature{
        body: parse_body(function, aliases, context),
        private: private?(type)
      }

  # simple call node
  defp parse_body({term, _, children} = ast, aliases, context)
       when is_atom_macro(ast),
       do: %Call{
         name: to_string(term),
         arguments: Enum.map(children, &Parser.parse(&1, aliases, context))
       }

  defp private?(:def), do: false
  defp private?(:defp), do: true
end
