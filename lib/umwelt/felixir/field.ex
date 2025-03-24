defmodule Umwelt.Felixir.Field do
  @moduledoc "Parses Struct definition AST"

  alias Umwelt.Felixir.{Alias, Literal}

  @type t() :: %__MODULE__{
          name: String.t(),
          type: %Alias{} | %Literal{},
          value: map
        }

  defstruct name: "", type: %Literal{type: :anything}, value: %{}
end
