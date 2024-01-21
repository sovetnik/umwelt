defmodule Umwelt.Parser.Pipe do
  @moduledoc "Parses Pipe AST"

  alias Umwelt.Parser

  def parse({:|>, _, [first_arg, {call, _, rest_args}]}, aliases) do
    {call, [], [first_arg | rest_args]}
    |> Parser.parse(aliases)
  end
end
