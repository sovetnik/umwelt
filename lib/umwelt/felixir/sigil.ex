defmodule Umwelt.Felixir.Sigil do
  @moduledoc "Felixir Sigil AST"

  @type t() :: %__MODULE__{string: String.t(), mod: String.t()}

  defstruct string: "", mod: ""
end
