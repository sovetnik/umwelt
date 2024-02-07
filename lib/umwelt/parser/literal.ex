defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses value value AST"

  def parse(value) when is_binary(value),
    do: %{body: value, kind: :value, type: [:Binary]}

  def parse(value) when is_float(value),
    do: %{body: to_string(value), kind: :value, type: [:Float]}

  def parse(value) when is_integer(value),
    do: %{body: to_string(value), kind: :value, type: [:Integer]}

  def parse(true),
    do: %{body: "true", kind: :value, type: [:Boolean]}

  def parse(false),
    do: %{body: "false", kind: :value, type: [:Boolean]}

  def parse(value) when is_atom(value),
    do: %{body: to_string(value), kind: :value, type: [:Atom]}

  def parse({value, _, nil}) when is_atom(value),
    do: %{body: to_string(value), kind: :variable, type: [:Variable]}
end
