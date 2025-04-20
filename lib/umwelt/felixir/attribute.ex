defmodule Umwelt.Felixir.Attribute do
  @moduledoc "Felixir Attribute"

  alias Umwelt.Felixir.{Structure, Value}

  @type t() :: %__MODULE__{
          name: String.t(),
          value: Structure.t() | Value.t()
        }

  defstruct name: "", value: nil
end
