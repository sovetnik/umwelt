defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses value AST"

  def type_of(:any), do: %{kind: :Literal, type: :anything}

  def type_of(type) when type in ~w|atom boolean binary float integer read_attr|a,
    do: %{kind: :Literal, type: type}

  def type_of(type) when type in ~w|bitstring list map tuple|a,
    do: %{kind: :Structure, type: type}

  def parse({:@, _, [{term, _, nil}]}) do
    %{body: to_string(term), kind: :Value, type: type_of(:read_attr)}
  end

  def parse(value) when is_binary(value),
    do: %{body: value, kind: :Value, type: type_of(:binary)}

  def parse(value) when is_float(value),
    do: %{body: to_string(value), kind: :Value, type: type_of(:float)}

  def parse(value) when is_integer(value),
    do: %{body: to_string(value), kind: :Value, type: type_of(:integer)}

  def parse(true),
    do: %{body: "true", kind: :Value, type: type_of(:boolean)}

  def parse(false),
    do: %{body: "false", kind: :Value, type: type_of(:boolean)}

  def parse(nil),
    do: %{body: "nil", kind: :Value, type: type_of(:atom)}

  def parse(value) when is_atom(value),
    do: %{body: to_string(value), kind: :Value, type: type_of(:atom)}

  def parse({value, _, nil}) when is_atom(value),
    do: %{body: to_string(value), kind: :Variable, type: type_of(:any)}
end
