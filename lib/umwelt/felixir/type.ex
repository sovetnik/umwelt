defmodule Umwelt.Felixir.Type do
  @moduledoc "Type AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          doc: String.t(),
          spec: map
        }

  defstruct name: "", doc: "", spec: %{}
end
