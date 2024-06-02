defmodule Umwelt.Parser.Sigil do
  @moduledoc "Parses Sigil AST"

  require Logger
  @log_message "Unknown AST skipped in Sigil.parse"

  @kernel_sigils ~w|C c D N R r S s T U W w|
  @sigil_names Enum.map(@kernel_sigils, &String.to_atom("sigil_#{&1}"))

  defguard is_sigil(term) when term in @sigil_names

  def parse({sigil, [delimiter: delimiter, line: _], [value, mods]}, _aliases)
      when is_sigil(sigil),
      do: %{
        body: extract_value(value),
        kind: :Sigil,
        note: to_string(sigil) <> delimiter <> to_string(mods)
      }

  def parse(ast, _aliases) do
    Logger.warning("#{@log_message}/2\n #{inspect(ast)}")
    nil
  end

  defp extract_value({:<<>>, _, values}),
    do: Enum.map_join(values, &extract_string/1)

  defp extract_string(str) when is_binary(str), do: str

  defp extract_string(
         {:"::", _, [{{:., _, [Kernel, :to_string]}, _, [term]}, {:binary, _, nil}]}
       ),
       do: "\#{:#{to_string(term)}}"
end
