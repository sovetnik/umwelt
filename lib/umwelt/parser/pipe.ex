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

  def parse({term, _, children}, aliases)
      when is_left_operator(term),
      do: %{
        body: to_string(term),
        kind: :Pipe,
        values: Parser.parse_list(children, aliases)
      }

  def parse({term, _, [left | right]}, aliases)
      when is_right_operator(term),
      do: %{
        body: to_string(term),
        kind: :Pipe,
        left: Parser.maybe_list_parse(left, aliases),
        right: Parser.maybe_list_parse(right, aliases)
      }

  def parse({term, _, children}, aliases)
      when is_right_operator(term),
      do: %{
        body: to_string(term),
        kind: :Pipe,
        values: Parser.parse_list(children, aliases)
      }

  def parse({term, _, _}, _) when is_right_operator(term),
    do: %{
      body: "complex_arg",
      kind: :Variable,
      type: %{kind: :Literal, type: :anything}
    }
end
