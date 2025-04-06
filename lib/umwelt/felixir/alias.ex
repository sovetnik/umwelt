defmodule Umwelt.Felixir.Alias do
  @moduledoc "Felixir Alias"

  alias Umwelt.Felixir.Alias

  @type t() :: %__MODULE__{
          name: String.t(),
          path: list
        }

  defstruct name: "", path: []

  def from_path(path) do
    %__MODULE__{
      name: List.last(path),
      path: path
    }
  end

  def choose(%Alias{name: name} = alias, aliases),
    do: Enum.find(aliases, alias, &match?(%Alias{name: ^name}, &1))
end
