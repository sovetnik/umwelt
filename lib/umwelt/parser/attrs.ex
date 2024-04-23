defmodule Umwelt.Parser.Attrs do
  @moduledoc "Parses @attr AST"

  require Logger
  @log_message "Unknown AST skipped in Attrs.parse"
  alias Umwelt.Parser

  def parse({:@, _, children}) do
    case children do
      [{:moduledoc, _, children} | _] ->
        %{:moduledoc => children}

      [{:doc, _, children} | _] ->
        %{:doc => children}

      [{:impl, _, children} | _] ->
        %{:impl => Parser.parse(children, [])}

      # parse it with function,
      # to determine arguments types
      [{:spec, _, children} | _] ->
        %{:spec => children}

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
