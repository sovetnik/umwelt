defmodule Umwelt.Felixir.Variable do
  @moduledoc "Felixir Variable AST"

  alias Umwelt.Argument
  alias Umwelt.Felixir.{Alias, Call, Literal, Structure, Variable}

  @type t() :: %__MODULE__{
          body: String.t(),
          type: Alias.t() | Literal.t()
        }

  defstruct body: "", type: %Literal{type: :anything}

  defimpl Argument, for: __MODULE__ do
    def resolve(variable, %Call{} = call),
      do: Map.put(variable, :type, call)

    def resolve(variable, %Literal{} = literal),
      do: Map.put(variable, :type, literal)

    def resolve(variable, %Variable{type: type}),
      do: Map.put(variable, :type, type)

    def resolve(variable, %Structure{type: type}),
      do: Map.put(variable, :type, type)
  end
end
