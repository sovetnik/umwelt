defmodule Umwelt.Felixir.Operator do
  @moduledoc "Left & Right Operator AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          left: any,
          right: any
        }

  defstruct name: "", left: nil, right: nil

  alias Umwelt.Felixir.{Literal, Operator, Structure, Variable}

  def type_equation(
        %Operator{
          name: "default",
          left: %{type: %Literal{type: :anything}} = left,
          right: %{type: right_type}
        } = op
      ) do
    left = Map.put(left, :type, right_type)
    Map.put(op, :left, left)
  end

  def type_equation(
        %Operator{
          name: "match",
          left: %{type: left_type},
          right: %{type: %Literal{type: :anything}} = right
        } = op
      ) do
    right = Map.put(right, :type, left_type)
    Map.put(op, :right, right)
  end

  defimpl Umwelt.Argument, for: __MODULE__ do
    def resolve(
          %Operator{
            name: "match",
            left: %Structure{type: type},
            right: %Variable{} = variable
          },
          _other
        ),
        do: Map.put(variable, :type, type)

    def resolve(%Operator{name: "default", left: variable}, %{type: type}),
      do: Map.put(variable, :type, type)
  end
end
