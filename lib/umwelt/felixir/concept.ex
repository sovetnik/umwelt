defmodule Umwelt.Felixir.Concept do
  @moduledoc "Concept (module) of parsed AST"

  # require Logger
  # @log_message "Unknown AST skipped in Concept."

  alias Umwelt.Felixir.{Attribute, Call, Field}
  alias Umwelt.Parser

  import Umwelt.Parser.Util, only: [string_or: 2]

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

  def from_path(path) do
    %__MODULE__{
      name: List.last(path),
      context: path,
      note: "Description of #{List.last(path)} concept"
    }
  end

  def combine(block, concept, types) when is_list(block) do
    Enum.reduce(block, concept, fn
      %{moduledoc: [value]}, concept ->
        Map.put(concept, :note, string_or(value, "Description of #{concept.name}"))

      %{defstruct: fields}, concept ->
        fields
        |> add_types(types, concept.aliases, concept.context)
        |> then(&Map.put(concept, :fields, &1))

      %{defguard: value}, %{guards: attrs} = concept ->
        Map.put(concept, :guards, [value | attrs])

      %Attribute{} = value, %{attrs: attrs} = concept ->
        Map.put(concept, :attrs, [value | attrs])

      %Call{} = value, %{calls: calls} = concept ->
        Map.put(concept, :calls, [value | calls])

      # doc and impl related to function and parsed in functions
      %{typedoc: _}, concept ->
        concept

      %{doc: _}, concept ->
        concept

      %{impl: _}, concept ->
        concept

      %{spec: _}, concept ->
        concept

      children, concept when is_list(children) ->
        concept

      _other, concept ->
        # Logger.warning("#{@log_message}combine/2\n #{inspect(other, pretty: true)}")
        concept
    end)
  end

  defp add_types(fields, types, aliases, context) do
    index = Parser.Struct.types(types, aliases, context)
    Enum.map(fields, &Field.add_type(&1, index))
  end
end
