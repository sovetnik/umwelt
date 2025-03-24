defmodule Umwelt.Felixir.Structure do
  @moduledoc "Felixir Structure AST"

  alias Umwelt.Argument
  alias Umwelt.Felixir.{Alias, Call, Literal, Variable}

  @type t() :: %__MODULE__{
          type: Literal.t(),
          elements: list
        }

  defstruct type: nil, elements: []

  defimpl Argument, for: __MODULE__ do
    def resolve(variable, %Variable{
          type: %Call{name: "t", arguments: [], context: context}
        }) do
      Map.put(variable, :type, Alias.from_path(context))
    end
  end
end
