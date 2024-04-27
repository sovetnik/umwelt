defmodule Umwelt.Helpers do
  @moduledoc "Helper functions"

  def string_or(value, replace) do
    case value do
      value when is_binary(value) ->
        string =
          value
          |> String.split("\n")
          |> List.first()

        if String.length(string) < 255 do
          string
        else
          replace
        end

      _ ->
        replace
    end
  end

  def upper_atom(atom) do
    atom |> to_string |> Macro.camelize() |> String.to_atom()
  end
end
