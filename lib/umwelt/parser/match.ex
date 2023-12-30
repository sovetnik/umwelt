defmodule Umwelt.Parser.Match do
  @moduledoc "Parses Match AST"

  alias Umwelt.Parser

  def parse({:=, _, [left, {name, _, nil}]}, aliases),
    do: %{:body => to_string(name), :match => Parser.parse(left, aliases)}
end
