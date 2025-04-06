defmodule Umwelt.Felixir.Type do
  @moduledoc "Type AST"

  alias Umwelt.Felixir.{Alias, Literal}

  @type t() :: %__MODULE__{
          name: String.t(),
          doc: String.t(),
          spec: %Alias{} | %Literal{}
        }

  defstruct name: "", doc: "", spec: %{}
end
