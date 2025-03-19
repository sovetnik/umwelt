defmodule Umwelt.Felixir.Call do
  @moduledoc "Parses Call AST"

  alias Umwelt.Felixir.{Literal, Variable}

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

  def add_types(call, nil), do: call

  def add_types(call, value) do
    call
    |> Map.put(
      :arguments,
      Variable.add_types(call.arguments, value.arguments)
    )
    |> Map.put(:type, value.type)
  end
end
