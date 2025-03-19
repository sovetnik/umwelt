defmodule Umwelt.Felixir.Variable do
  @moduledoc "Felixir Variable AST"

  alias Umwelt.Felixir.{Alias, Call, Literal, Operator, Structure, Variable}

  @type t() :: %__MODULE__{
          body: String.t(),
          type: Alias.t() | Literal.t()
        }

  defstruct body: "", type: %Literal{type: :anything}

  def add_types(arguments, types) do
    arguments
    |> Enum.zip(types)
    |> Enum.map(&combine/1)
  end

  # when kind in ~w|Structure Variable|a
  defp combine({%Operator{left: variable}, %{type: type}}),
    do: Map.put(variable, :type, type)

  defp combine({%Structure{type: type}, %Variable{} = variable}),
    do: Map.put(variable, :type, type)

  defp combine({%Variable{} = variable, %Variable{type: type}}),
    do: Map.put(variable, :type, type)

  defp combine({%Variable{} = variable, %Call{} = call}),
    do: Map.put(variable, :type, call)

  defp combine({%Variable{} = variable, %Structure{type: type}}),
    do: Map.put(variable, :type, type)
end
