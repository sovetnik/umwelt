defmodule Umwelt.Parser.Types do
  @moduledoc "Extracts types"

  # require Logger
  # @log_message "Unknown AST skipped in Type reducer."

  alias Umwelt.Felixir.{Call, Function, Literal, Operator, Structure, Type, Value, Variable}

  import Umwelt.Parser.Literal, only: [is_literal: 1]
  import Umwelt.Parser.Util, only: [string_or: 2]

  def specify(term, types)

  def specify(%Function{body: body} = fun, types),
    do: Map.put(fun, :body, specify(body, types))

  def specify(%Operator{left: left} = op, types),
    do: Map.put(op, :left, specify(left, types))

  def specify(%Call{arguments: args} = call, types),
    do: Map.put(call, :arguments, Enum.map(args, &add_type(&1, types)))

  defp add_type(%Operator{} = op, _index),
    do: Operator.type_equation(op)

  defp add_type(%Call{name: name, type: type} = var, index),
    do: Map.put(var, :type, index[name] || type)

  defp add_type(%Structure{} = structure, _index), do: structure
  defp add_type(%Value{} = value, _index), do: value

  defp add_type(%Variable{type: %Call{name: name} = type} = var, index),
    do: Map.put(var, :type, index[name] || type)

  defp add_type(%Variable{body: name, type: %Literal{type: :anything}} = var, index),
    do: Map.put(var, :type, index[name] || maybe_literal(name))

  defp add_type(%Variable{type: %Literal{}} = var, _index), do: var
  defp add_type(%Variable{type: %Type{}} = variable, _index), do: variable

  defp add_type(%Variable{body: name} = var, index),
    do: Map.put(var, :type, index[name] || maybe_literal(name))

  def maybe_literal(name) do
    if is_literal(String.to_atom(name)) do
      %Literal{type: String.to_atom(name)}
    else
      %Literal{type: :anything}
    end
  end

  def extract(block_children) do
    Enum.reduce([[%Type{}] | block_children], fn
      %{typedoc: [%Value{type: %Literal{type: :string}, body: body}]}, [head | rest] ->
        [Map.put(head, :doc, string_or(body, "Description of type")) | rest]

      %{typedoc: value}, [head | rest] ->
        [Map.put(head, :doc, string_or(value, "Description of type")) | rest]

      %{type: %Call{name: name, type: type}}, [head | rest] ->
        [%Type{}, reduce(head, name, type) | rest]

      %{type: %Variable{body: name, type: type}}, [head | rest] ->
        [%Type{}, reduce(head, name, type) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}_extract_types/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&(%Type{name: ""} == &1))
    |> Enum.reverse()
  end

  defp reduce(type, name, spec) do
    type
    |> Map.put(:name, name)
    |> Map.put(:spec, spec)
  end
end
