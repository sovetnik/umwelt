defmodule Umwelt.Felixir.Pipe do
  @moduledoc "Pipe Operator AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          left: any,
          right: any
        }

  defstruct name: "", left: nil, right: nil
end
