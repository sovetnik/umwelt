defmodule Umwelt.Felixir.Structure do
  @moduledoc "Felixir Structure AST"

  alias Umwelt.Argument
  alias Umwelt.Felixir.{Alias, Literal, Variable}

  @type t() :: %__MODULE__{
          type: Literal.t(),
          elements: list
        }

  defstruct type: nil, elements: []

  defimpl Argument, for: __MODULE__ do
    def resolve(variable, %Variable{type: %Alias{} = alias}),
      do: Map.put(variable, :type, alias)

    def resolve(variable, %Variable{type: %Literal{type: :anything}}),
      do: variable
  end
end
