defmodule Umwelt.Felixir.Signature do
  @moduledoc "Parses Signature AST"

  alias Umwelt.Felixir.{Call, Signature}

  @type t() :: %__MODULE__{
          body: Call.t(),
          note: String.t(),
          private: boolean
        }

  defstruct note: "", body: nil, private: false

  # when kind in ~w|Function Signature|a
  def merge(%Signature{} = signature, %{body: body, note: note}) do
    signature
    |> Map.put(:note, note)
    |> Map.put(:body, Call.add_types(signature.body, body))
  end
end
