defmodule Umwelt.Felixir.Function do
  @moduledoc "Parses Function AST"

  alias Umwelt.Felixir.{Call, Function, Operator, Variable}

  @type t() :: %__MODULE__{
          body: Call.t(),
          note: String.t(),
          private: boolean,
          impl: any
        }

  defstruct note: "", body: nil, private: false, impl: nil

  def merge(fun, :body, nil), do: fun

  def merge(%Function{body: %Operator{left: left} = op} = fun, :body, value),
    do: Map.put(fun, :body, Map.put(op, :left, reduce(left, value)))

  def merge(%Function{body: %Call{} = call} = fun, :body, value),
    do: Map.put(fun, :body, reduce(call, value))

  defp reduce(call, value) do
    call
    |> Map.put(:arguments, add_types(call.arguments, value.arguments))
    |> Map.put(:type, value.type)
  end

  defp add_types(arguments, types) do
    arguments
    |> Enum.zip(types)
    |> Enum.map(&combine/1)
  end

  defp combine({%Variable{} = variable, %Variable{type: type}}),
    do: Map.put(variable, :type, type)

  defp combine({%Variable{} = variable, %Call{} = call}),
    do: Map.put(variable, :type, call)
end
