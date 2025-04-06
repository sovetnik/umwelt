defmodule Umwelt.Parser.Types do
  @moduledoc "Extracts types"

  # require Logger
  # @log_message "Unknown AST skipped in Type reducer."

  alias Umwelt.Felixir.{
    Alias,
    Call,
    Function,
    Literal,
    Operator,
    Signature,
    Structure,
    Type,
    Value,
    Variable
  }

  import Umwelt.Parser.Literal, only: [type_of: 1]
  import Umwelt.Parser.Util, only: [string_or: 2]

  def specify(term, types)

  def specify(%Function{body: body} = fun, types),
    do: Map.put(fun, :body, specify(body, types))

  def specify(%Operator{left: left} = op, types),
    do: Map.put(op, :left, specify(left, types))

  def specify(%Signature{body: body} = sign, types),
    do: Map.put(sign, :body, specify(body, types))

  def specify(%Call{arguments: args} = call, types),
    do: Map.put(call, :arguments, with_types(args, types))

  defp with_types(args, types) do
    Enum.map(args, fn
      %Call{name: name, type: type} = variable ->
        Map.put(variable, :type, types[name] || type)

      %Literal{} = literal ->
        literal

      %Operator{} = operator ->
        Operator.type_equation(operator)

      %Structure{} = structure ->
        structure

      %Value{} = value ->
        value

      %Variable{type: %Call{name: name} = type} = variable ->
        Map.put(variable, :type, types[name] || type)

      %Variable{body: name, type: %Literal{type: :anything}} = var ->
        Map.put(var, :type, types[name] || maybe_literal(name))

      %Variable{type: %Alias{}} = variable ->
        variable

      %Variable{type: %Literal{}} = variable ->
        variable

      %Variable{type: %Type{}} = variable ->
        variable
    end)
  end

  def maybe_literal(name), do: name |> String.to_atom() |> type_of()

  def extract(block_children, aliases) do
    Enum.reduce([[%Type{}] | block_children], fn
      %{typedoc: [%Value{type: %Literal{type: :string}, body: body}]}, [head | rest] ->
        [Map.put(head, :doc, string_or(body, "Description of type")) | rest]

      %{typedoc: value}, [head | rest] ->
        [Map.put(head, :doc, string_or(value, "Description of type")) | rest]

      %{type: %Call{name: name, type: type}}, [head | rest] ->
        [%Type{}, combine(head, name, type, aliases) | rest]

      %{type: %Variable{body: name, type: type}}, [head | rest] ->
        [%Type{}, combine(head, name, type, aliases) | rest]

      _other, acc ->
        # Logger.warning("#{@log_message}_extract_types/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&(%Type{name: ""} == &1))
    |> Enum.reverse()
  end

  defp combine(type, name, %Alias{} = alias, aliases) do
    type
    |> Map.put(:name, name)
    |> Map.put(:spec, Alias.choose(alias, aliases))
  end

  defp combine(type, name, spec, _aliases),
    do: type |> Map.put(:name, name) |> Map.put(:spec, spec)
end
