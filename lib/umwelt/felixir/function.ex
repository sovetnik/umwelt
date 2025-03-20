defmodule Umwelt.Felixir.Function do
  @moduledoc "Parses Function AST"

  alias Umwelt.Argument
  alias Umwelt.Felixir.{Call, Function, Operator}

  @type t() :: %__MODULE__{
          body: Call.t(),
          note: String.t(),
          private: boolean,
          impl: any
        }

  defstruct note: "", body: nil, private: false, impl: nil

  defimpl Argument, for: __MODULE__ do
    def resolve(fun, nil), do: fun

    def resolve(%Function{body: %Operator{left: left} = op} = fun, value),
      do: Map.put(fun, :body, Map.put(op, :left, Argument.resolve(left, value)))

    def resolve(%Function{body: %Call{} = call} = fun, head),
      do: Map.put(fun, :body, Argument.resolve(call, head))
  end
end
