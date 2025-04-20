defmodule Umwelt.Felixir.Field do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Felixir.{Alias, Field, Literal}

  @type t() :: %__MODULE__{
          name: String.t(),
          type: %Alias{} | %Literal{},
          value: map
        }

  defstruct name: "", type: %Literal{type: :anything}, value: %{}

  def add_type(%Field{name: field_name} = field, index) do
    case index[String.to_atom(field_name)] do
      nil -> field
      type -> Map.put(field, :type, type)
    end
  end
end
