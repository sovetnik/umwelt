defmodule Umwelt.Parser.Util do
  @moduledoc "Reducer for AST"

  def string_or(value, replace) do
    case value do
      value when is_binary(value) ->
        string =
          value
          |> String.split("\n")
          |> List.first()

        if String.length(string) < 255,
          do: string,
          else: replace

      _ ->
        replace
    end
  end
end
