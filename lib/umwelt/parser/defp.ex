defmodule Umwelt.Parser.Defp do
  @moduledoc "Parses Function AST"

  require Logger
  @log_message "Unknown AST skipped in Def.parse"

  import Umwelt.Parser.Macro, only: [is_atom_macro: 1]

  def parse({:defp, _, [ast, [do: _]]}, aliases)
      when is_atom_macro(ast),
      do: parse_call(ast, aliases)

  def parse({:defp, _, [function]}, aliases),
    do: parse_call(function, aliases)

  def parse(ast, _aliases) do
    Logger.warning("#{@log_message}/2\n #{inspect(ast)}")
    nil
  end

  defp parse_call({term, _, _children}, _aliases),
    do: %{kind: :PrivateFunction, body: to_string(term)}
end
