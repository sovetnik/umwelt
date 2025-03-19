defmodule Umwelt.Felixir.Function do
  @moduledoc "Parses Function AST"

  alias Umwelt.Felixir.{Call, Function, Operator}

  @type t() :: %__MODULE__{
          body: Call.t(),
          note: String.t(),
          private: boolean,
          impl: any
        }

  defstruct note: "", body: nil, private: false, impl: nil

  def merge(fun, nil), do: fun

  def merge(%Function{body: %Operator{left: left} = op} = fun, value),
    do: Map.put(fun, :body, Map.put(op, :left, Call.add_types(left, value)))

  def merge(%Function{body: %Call{} = call} = fun, head),
    do: Map.put(fun, :body, Call.add_types(call, head))
end
