defmodule Umwelt.Parser.Pipe do
  @moduledoc "Parses Pipe AST"

  alias Umwelt.Felixir.Pipe
  alias Umwelt.Parser

  defguard is_left_operator(term)
           when term in [:|>, :<<<, :>>>, :<<~, :~>>, :<~, :~>, :<~>, :<-]

  defguard is_right_operator(term)
           when term in [:|]

  defguard is_pipe_operator(term)
           when is_left_operator(term) or is_right_operator(term)

  def parse({:|>, _, [first_arg, {call, _, rest_args}]}, aliases, context),
    do: {call, [], [first_arg | rest_args]} |> Parser.parse(aliases, context)

  def parse({term, _, [left, right]}, aliases, context),
    do: %Pipe{
      name: to_string(term),
      left: Parser.maybe_list_parse(left, aliases, context),
      right: Parser.maybe_list_parse(right, aliases, context)
    }
end
