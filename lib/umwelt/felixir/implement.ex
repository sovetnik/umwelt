defmodule Umwelt.Felixir.Implement do
  @moduledoc "Parses Implement AST"

  alias Umwelt.Felixir.Alias

  @type t() :: %__MODULE__{
          name: String.t(),
          note: String.t(),
          aliases: list,
          functions: list,
          context: list,
          protocol: Alias.t(),
          subject: Alias.t()
        }

  defstruct name: "",
            note: "",
            aliases: [],
            functions: [],
            context: [],
            protocol: [],
            subject: []
end
