defmodule Umwelt.Parser.Def do
  @moduledoc "Parses Function AST"

  require Logger
  @log_message "Unknown AST skipped in Def.parse"

  alias Umwelt.Felixir.{Call, Function}
  alias Umwelt.Parser

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({type, _, [{:when, _, _} = ast]}, aliases, context),
    do: %Function{body: Parser.Operator.parse(ast, aliases, context), private: private?(type)}

  def parse({type, _, [{:when, _, _} = ast, [do: _]]}, aliases, context),
    do: %Function{body: Parser.Operator.parse(ast, aliases, context), private: private?(type)}

  def parse({type, _, [{function, _, nil}, [do: _]]}, aliases, context),
    do: %Function{body: parse_body({function, [], []}, aliases, context), private: private?(type)}

  def parse({type, _, [ast, [do: _]]}, aliases, context)
      when is_atom_macro(ast),
      do: %Function{body: parse_body(ast, aliases, context), private: private?(type)}

  def parse({type, _, [function]}, aliases, context)
      when is_atom_macro(function),
      do: %Function{body: parse_body(function, aliases, context), private: private?(type)}

  def parse(ast, _aliases, _context) do
    Logger.warning("#{@log_message}/2\n #{inspect(ast)}")
    nil
  end

  defp private?(:def), do: false
  defp private?(:defp), do: true

  # simple call node
  defp parse_body({term, _, children} = ast, aliases, context)
       when is_atom_macro(ast),
       do: %Call{
         name: to_string(term),
         arguments: Enum.map(children, &Parser.parse(&1, aliases, context))
       }
end
