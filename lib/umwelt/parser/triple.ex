defmodule Umwelt.Parser.Triple do
  @moduledoc "Parses various AST"

  alias Umwelt.Parser

  def parse({_, _, nil} = ast, _aliases),
    do: Parser.Literal.parse(ast)

  # def parse({:@, _, _} = ast, _aliases),
  #   do: Parser.Attrs.parse(ast)

  def parse({:defmodule, _, _} = ast, context),
    do: Parser.Defmodule.parse(ast, context)

  def parse({:def, _, _} = ast, aliases),
    do: Parser.Def.parse(ast, aliases)

  def parse({:{}, _, _} = ast, aliases),
    do: Parser.Tuple.parse(ast, aliases)

  def parse({:=, _, _} = ast, aliases),
    do: Parser.Match.parse(ast, aliases)

  def parse({:%, _, _} = ast, aliases),
    do: Parser.Struct.parse(ast, aliases)

  def parse({:%{}, _, children}, _aliases),
    do: %{struct: children}

  def parse({:\\, _, children}, aliases),
    do: %{default_value: Parser.parse(children, aliases)}
end
