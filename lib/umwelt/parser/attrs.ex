defmodule Umwelt.Parser.Attrs do
  @moduledoc "Parses @attr AST"

  require Logger
  @log_message "Unknown AST skipped in Attrs.parse"

  alias Umwelt.Parser

  def parse({:@, _, children}, context \\ []) do
    case children do
      [{:moduledoc, _, children} | _] ->
        %{moduledoc: children}

      [{:impl, _, children} | _] ->
        %{impl: Parser.maybe_list_parse(children, [])}

      [{:doc, _, children} | _] ->
        %{doc: children}

      [{:spec, _, children} | _] ->
        %{spec: Parser.Typespec.parse(children, [], context)}

      [{:type, _, children} | _] ->
        %{type: Parser.Typespec.parse(children, [], context)}

      [{:typedoc, _, children} | _] ->
        %{typedoc: Parser.maybe_list_parse(children, [])}

      [{constant, _, [child]} | _] ->
        %{
          body: to_string(constant),
          kind: :Attr,
          value: Parser.parse(child, [])
        }

      ast ->
        Logger.warning("#{@log_message}_block/2\n #{inspect(ast)}")
        %{unknown: "unknown attr"}
    end
  end
end
