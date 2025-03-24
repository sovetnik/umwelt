defmodule Umwelt.Felixir.Call do
  @moduledoc "Parses Call AST"

  alias Umwelt.Argument
  alias Umwelt.Felixir.Literal

  @type t() :: %__MODULE__{
          name: String.t(),
          note: String.t(),
          arguments: list,
          context: list,
          type: any
        }

  defstruct name: "",
            note: "",
            arguments: [],
            context: [],
            type: %Literal{type: :anything}

  defimpl Argument, for: __MODULE__ do
    def resolve(fun, nil), do: fun

    def resolve(call, value) do
      call
      |> Map.put(:type, value.type)
      |> Map.put(:arguments, Argument.resolve(call.arguments, value.arguments))
    end
  end
end
