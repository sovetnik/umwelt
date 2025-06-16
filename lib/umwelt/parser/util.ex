defmodule Umwelt.Parser.Util do
  @moduledoc "Reducer for AST"

  def string_or(value, replace) do
    case value do
      string when is_binary(string) ->
        if String.length(string) in 1..255,
          do: string,
          else: "#{String.slice(string, 0..250)}..."

      _ ->
        replace
    end
  end
end
