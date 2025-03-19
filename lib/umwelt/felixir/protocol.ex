defmodule Umwelt.Felixir.Protocol do
  @moduledoc "Parses Protocol AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          note: String.t(),
          aliases: list,
          signatures: list,
          context: list
        }

  defstruct name: "",
            note: "",
            aliases: [],
            signatures: [],
            context: []
end
