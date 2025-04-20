defmodule Umwelt.Felixir.Value do
  @moduledoc "Felixir Value AST"

  alias Umwelt.Felixir.Literal

  @type t() :: %__MODULE__{
          body: String.t(),
          type: Literal.t()
        }

  defstruct body: "", type: %Literal{type: :anything}
end
