defmodule Umwelt.Felixir.Variable do
  @moduledoc "Felixir Variable AST"

  alias Umwelt.Felixir.{Alias, Literal}

  @type t() :: %__MODULE__{
          body: String.t(),
          type: Alias.t() | Literal.t()
        }

  defstruct body: "", type: %Literal{type: :anything}
end
