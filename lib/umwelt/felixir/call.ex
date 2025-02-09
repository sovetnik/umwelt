defmodule Umwelt.Felixir.Call do
  @moduledoc "Parses Call AST"

  alias Umwelt.Felixir.Literal

  @type t() :: %__MODULE__{
          name: String.t(),
          note: String.t(),
          arguments: list,
          context: list,
          type: any
        }

  defstruct name: "",
            note: "",
            arguments: [],
            context: [],
            type: %Literal{type: :anything}
end
