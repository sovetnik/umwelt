defmodule Umwelt.Parser.Attrs do
  @moduledoc "Parses @attr AST"

  alias Umwelt.Parser

  def parse({:@, _, children}) do
    case children do
      [{:moduledoc, _, children} | _] ->
        %{:moduledoc => children}

      [{:doc, _, children} | _] ->
        %{:doc => children}

      [{:impl, _, children} | _] ->
        %{:impl => Parser.parse(children, [])}

      # [{:spec, _, children} | _] ->
      #   %{:spec => children}

      [{constant, _, [child]} | _] ->
        %{
          body: to_string(constant),
          kind: :Attr,
          value: Parser.parse(child, [])
        }

        # _ ->
        #   nil
    end
  end
end
