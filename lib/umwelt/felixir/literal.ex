defmodule Umwelt.Felixir.Literal do
  @moduledoc "Felixir Literal AST"

  @type t() :: %__MODULE__{type: atom}

  defstruct type: :anything
end
