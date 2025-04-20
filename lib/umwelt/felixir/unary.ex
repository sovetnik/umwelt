defmodule Umwelt.Felixir.Unary do
  @moduledoc "Felixir Unary operator AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          expr: any
        }

  defstruct name: "", expr: nil
end
