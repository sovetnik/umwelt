defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses Literal AST"

  def parse(literal) when is_binary(literal),
    do: %{body: literal, kind: :literal, type: [:Binary]}

  def parse(literal) when is_float(literal),
    do: %{body: to_string(literal), kind: :literal, type: [:Float]}

  def parse(literal) when is_integer(literal),
    do: %{body: to_string(literal), kind: :literal, type: [:Integer]}

  def parse(true),
    do: %{body: "true", kind: :literal, type: [:Boolean]}

  def parse(false),
    do: %{body: "false", kind: :literal, type: [:Boolean]}

  def parse(literal) when is_atom(literal),
    do: %{body: to_string(literal), kind: :literal, type: [:Atom]}

  def parse({literal, _, nil}) when is_atom(literal),
    do: %{body: to_string(literal), kind: :variable, type: [:Variable]}
end
