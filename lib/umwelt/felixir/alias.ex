defmodule Umwelt.Felixir.Alias do
  @moduledoc "Felixir Alias"

  @type t() :: %__MODULE__{
          name: String.t(),
          path: list
        }

  defstruct name: "", path: []
end
