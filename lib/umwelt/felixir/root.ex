defmodule Umwelt.Felixir.Root do
  @moduledoc "Root of Concept tree from parsed AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          note: String.t(),
          aliases: list,
          attrs: list,
          calls: list,
          context: list,
          fields: list,
          functions: list,
          guards: list,
          types: list
        }

  defstruct name: "",
            note: "",
            aliases: [],
            attrs: [],
            calls: [],
            context: [],
            fields: [],
            functions: [],
            guards: [],
            types: []
end
