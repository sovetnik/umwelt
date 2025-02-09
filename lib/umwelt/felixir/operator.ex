defmodule Umwelt.Felixir.Operator do
  @moduledoc "Left & Right Operator AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          left: any,
          right: any
        }

  defstruct name: "", left: nil, right: nil

  alias Umwelt.Felixir.{Literal, Operator}

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

  def type_equation(
        %Operator{
          name: "membership"
          # left: %{type: left_type},
          # right: %{type: %Literal{type: :anything}} = right
        } = op
      ) do
    op
  end
end

# %Umwelt.Felixir.Operator{
#   name: "membership",
#   left: %Umwelt.Felixir.Variable{body: "foo", type: %Umwelt.Felixir.Literal{type: :anything}},
#   right: [
#     %Umwelt.Felixir.Value{body: "bar", type: %Umwelt.Felixir.Literal{type: :atom}},
#     %Umwelt.Felixir.Value{body: "baz", type: %Umwelt.Felixir.Literal{type: :atom}}
#   ]
# }
