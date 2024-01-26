defmodule Umwelt.Parser.Pipe do
  @moduledoc "Parses Pipe AST"

  alias Umwelt.Parser

  defguard is_left_operator(term)
           when term in [:|>, :<<<, :>>>, :<<~, :~>>, :<~, :~>, :<~>, :<-]

  defguard is_right_operator(term)
           when term in [:|]

  defguard is_pipe_operator(term)
           when is_left_operator(term) or is_right_operator(term)

  def parse({:|>, _, [first_arg, {call, _, rest_args}]}, aliases) do
    {call, [], [first_arg | rest_args]}
    |> Parser.parse(aliases)
  end

  def parse({term, _, children}, aliases),
    do: %{
      body: to_string(term),
      kind: :pipe,
      values: Parser.parse(children, aliases)
    }
end
