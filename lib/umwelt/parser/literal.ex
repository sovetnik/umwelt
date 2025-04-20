defmodule Umwelt.Parser.Literal do
  @moduledoc "Parses value AST"
  alias Umwelt.Felixir.{Literal, Value, Variable}

  defguard is_literal_term(term)
           when term in ~w|atom boolean binary float integer read_attr string|a

  defguard is_literal_structure(term)
           when term in ~w|bitstring list map tuple|a

  defguard is_literal(term)
           when is_literal_term(term) or
                  is_literal_structure(term)

  def type_of(:any), do: %Literal{type: :anything}

  def type_of(type) when is_literal(type),
    do: %Literal{type: type}

  def type_of(_), do: %Literal{type: :anything}

  def parse({:@, _, [{term, _, nil}]}),
    do: %Value{body: to_string(term), type: type_of(:read_attr)}

  def parse(value) when is_binary(value) do
    if String.valid?(value) do
      %Value{body: value, type: type_of(:string)}
    else
      %Value{body: value, type: type_of(:binary)}
    end
  end

  def parse(value) when is_float(value),
    do: %Value{body: to_string(value), type: type_of(:float)}

  def parse(value) when is_integer(value),
    do: %Value{body: to_string(value), type: type_of(:integer)}

  def parse(true),
    do: %Value{body: "true", type: type_of(:boolean)}

  def parse(false),
    do: %Value{body: "false", type: type_of(:boolean)}

  def parse(nil),
    do: %Value{body: "nil", type: type_of(:atom)}

  def parse(value) when is_atom(value),
    do: %Value{body: to_string(value), type: type_of(:atom)}

  def parse({value, _, nil}) when is_atom(value),
    do: %Variable{body: to_string(value), type: type_of(:any)}
end
