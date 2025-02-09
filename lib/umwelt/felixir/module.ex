defmodule Umwelt.Felixir.Module do
  @moduledoc "Felixir Module AST"

  @type t() :: %__MODULE__{
          name: String.t(),
          attrs: list,
          calls: list,
          context: list,
          fields: list,
          functions: list,
          guards: list,
          types: list
        }

  defstruct name: "",
            attrs: [],
            calls: [],
            context: [],
            fields: [],
            functions: [],
            guards: [],
            types: []
end
