defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses value value AST"

  def parse(value) when is_binary(value),
    do: %{body: value, kind: :Value, type: [:Binary]}

  def parse(value) when is_float(value),
    do: %{body: to_string(value), kind: :Value, type: [:Float]}

  def parse(value) when is_integer(value),
    do: %{body: to_string(value), kind: :Value, type: [:Integer]}

  def parse(true),
    do: %{body: "true", kind: :Value, type: [:Boolean]}

  def parse(false),
    do: %{body: "false", kind: :Value, type: [:Boolean]}

  def parse(value) when is_atom(value),
    do: %{body: to_string(value), kind: :Value, type: [:Atom]}

  def parse({value, _, nil}) when is_atom(value),
    do: %{body: to_string(value), kind: :Variable, type: [:Variable]}
end
