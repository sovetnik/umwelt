defmodule Umwelt.Parser.Operator do
  @moduledoc """
    Parses Operator AST:

    ^ - pin operator
    . - dot operator
    = - match operator
    & - capture operator
    :: - type operator
  """

  require Logger
  @log_message "Unknown AST skipped in Operator.parse"
  alias Umwelt.Felixir.{Operator, Unary}
  alias Umwelt.Parser

  defguard is_special_operator(term)
           when term in [:^, :., :=, :&, :"::", :|, :<>]

  defguard is_comparison_operator(term)
           when term in [:==, :!=, :===, :!==, :<, :<=, :>, :>=]

  defguard is_other_operator(term)
           when term in [:\\, :in, :when]

  defguard is_relaxed_bool_operator(term)
           when term in [:&&, :||, :!]

  defguard is_strict_bool_operator(term)
           when term in [:and, :or, :not]

  defguard is_unary(term)
           when term in [:!, :^, :not, :&, :/]

  defguard is_operator(term)
           when is_unary(term) or
                  is_special_operator(term) or
                  is_comparison_operator(term) or
                  is_other_operator(term) or
                  is_relaxed_bool_operator(term) or
                  is_strict_bool_operator(term)

  # compactize Kernel calls
  def parse({{:., _, _}, _, _} = ast, aliases, context),
    do: Parser.Call.parse(ast, aliases, context)

  def parse({:\\, _, [left, right]}, aliases, context),
    do: %Operator{
      name: "default",
      left: Parser.parse(left, aliases, context),
      right: Parser.parse(right, aliases, context)
    }

  def parse({:=, _, [left, right]}, aliases, context),
    do: %Operator{
      name: "match",
      left: Parser.parse(left, aliases, context),
      right: Parser.parse(right, aliases, context)
    }

  def parse({:in, _, [left, right]}, aliases, context) when is_list(right),
    do: %Operator{
      name: "membership",
      left: Parser.parse(left, aliases, context),
      right: Parser.parse_list(right, aliases, context)
    }

  def parse({:|, _, [head, tail]}, aliases, context),
    do: %Operator{
      name: "alter",
      left: Parser.parse(head, aliases, context),
      right: Parser.parse(tail, aliases, context)
    }

  # def parse({:^, _, [left, {name, _, nil}]}, aliases),
  #   do: %{
  #     body: to_string(name),
  #     kind: :pin,
  #     term: Parser.parse(left, aliases)
  #   }

  # def parse({:&, _, [left, {name, _, nil}]}, aliases),
  #   do: %{
  #     body: to_string(name),
  #     kind: :capture,
  #     term: Parser.parse(left, aliases)
  #   }

  def parse({:"::", _, _} = ast, aliases, context),
    do: Parser.Typespec.parse(ast, aliases, context)

  def parse({term, _, [expr]}, aliases, context) when is_unary(term),
    do: %Unary{
      name: to_string(term),
      expr: Parser.parse(expr, aliases, context)
    }

  def parse({:when, _, [left, right]}, aliases, context),
    do: %Operator{
      name: "when",
      left: Parser.maybe_list_parse(left, aliases, context),
      right: Parser.maybe_list_parse(right, aliases, context)
    }

  def parse({term, _, [left, right]}, aliases, context) when is_atom(term),
    do: %Operator{
      name: to_string(term),
      left: Parser.maybe_list_parse(left, aliases, context),
      right: Parser.maybe_list_parse(right, aliases, context)
    }

  def parse(ast, _aliases) do
    Logger.warning("#{@log_message}/2\n #{inspect(ast)}")
    nil
  end
end
