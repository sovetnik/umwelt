defmodule Umwelt.Parser.Attrs do
  @moduledoc "Parses @attr AST"

  alias Umwelt.Parser

  def parse({:@, _, children}) do
    case children do
      [{:moduledoc, _, children} | _] ->
        %{:moduledoc => children}

      [{:doc, _, children} | _] ->
        %{:doc => children}

      # [{:spec, _, children} | _] ->
      #   %{:spec => children}

      [{constant, _, children} | _] ->
        %{constant => Parser.parse(children, [])}

        # _ ->
        #   nil
    end
  end
end
