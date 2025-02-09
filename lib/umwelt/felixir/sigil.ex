defmodule Umwelt.Felixir.Sigil do
  @moduledoc "Felixir Sigil AST"

  @type t() :: %__MODULE__{
          string: String.t(),
          mod: any
        }

  defstruct string: "", mod: nil
end
