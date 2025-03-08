defmodule Umwelt.Felixir.Structure do
  @moduledoc "Felixir Structure AST"
  alias Umwelt.Felixir.Literal

  @type t() :: %__MODULE__{
          type: Literal.t(),
          elements: list
        }

  defstruct type: nil, elements: []
end
