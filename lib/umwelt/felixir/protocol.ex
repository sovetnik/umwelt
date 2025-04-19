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

  def from_path(path) do
    %__MODULE__{
      name: List.last(path),
      context: path,
      note: "Description of #{List.last(path)} protocol"
    }
  end
end
