defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses Literal AST"

  def parse(literal) when is_binary(literal),
    do: %{body: literal, kind: [:Binary]}

  def parse(literal) when is_float(literal),
    do: %{body: to_string(literal), kind: [:Float]}

  def parse(literal) when is_integer(literal),
    do: %{body: to_string(literal), kind: [:Integer]}

  def parse(true),
    do: %{body: "true", kind: [:Boolean]}

  def parse(false),
    do: %{body: "false", kind: [:Boolean]}

  def parse(literal) when is_atom(literal),
    do: %{body: to_string(literal), kind: [:Atom]}

  def parse({literal, _, nil}),
    do: %{body: to_string(literal), kind: [:Capture]}
end
