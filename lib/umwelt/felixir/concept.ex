defmodule Umwelt.Felixir.Concept do
  @moduledoc "Concept (module) of parsed AST"

  # require Logger
  # @log_message "Unknown AST skipped in Concept."

  alias Umwelt.Felixir.{Attribute, Call}

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
          specs: list,
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
            specs: [],
            types: []

  def combine(block_children, module) when is_list(block_children) do
    Enum.reduce(block_children, module, fn
      %{moduledoc: [value]}, module ->
        Map.put(module, :note, string_or(value, "Description of #{module.name}"))

      %{defstruct: fields}, module ->
        Map.put(module, :fields, fields)

      %{defguard: value}, %{guards: attrs} = module ->
        Map.put(module, :guards, [value | attrs])

      %Attribute{} = value, %{attrs: attrs} = module ->
        Map.put(module, :attrs, [value | attrs])

      %Call{} = value, %{calls: calls} = module ->
        Map.put(module, :calls, [value | calls])

      # doc and impl related to function and parsed in functions
      %{typedoc: _}, module ->
        module

      %{doc: _}, module ->
        module

      %{impl: _}, module ->
        module

      %{spec: _}, module ->
        module

      children, module when is_list(children) ->
        module

      _other, module ->
        # Logger.warning("#{@log_message}combine/2\n #{inspect(other, pretty: true)}")
        module
    end)
  end

  def combine(block_children, module) do
    combine([block_children], module)
  end
end
