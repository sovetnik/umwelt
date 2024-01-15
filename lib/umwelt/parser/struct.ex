defmodule Umwelt.Parser.Struct do
  @moduledoc "Parses %Struct{} AST"

  alias Umwelt.Parser

  def parse(
        {:%, _,
         [
           {:__aliases__, _, _} = ast,
           {:%{}, _, []}
         ]},
        aliases
      ),
      do: Parser.parse(ast, aliases)
end
