defmodule Umwelt.Parser.Comparison do
  @moduledoc "Parses Comparison AST"

  alias Umwelt.Parser

  defguard is_comparison_operator(term)
           when term in [:==, :!=, :===, :!==, :<, :<=, :>, :>=]

  defguard is_strict_bool_comparison(term)
           when term in [:and, :or, :not, :in]

  defguard is_relaxed_bool_comparison(term)
           when term in [:&&, :||, :!]

  defguard is_comparison(term)
           when is_comparison_operator(term) or
                  is_strict_bool_comparison(term) or
                  is_relaxed_bool_comparison(term)

  def parse({:in, _, [left, right]}, aliases) when is_list(right) do
    %{
      kind: :inclusion,
      body: "inclusion",
      left: Parser.parse(left, aliases),
      right: Parser.parse(right, aliases)
    }
  end

  def parse({term, _, [left, right]}, aliases)
      when is_comparison(term) do
    %{
      kind: :comparison,
      body: to_string(term),
      left: Parser.parse(left, aliases),
      right: Parser.parse(right, aliases)
    }
  end

  def parse({:not, _, [expr]}, aliases) do
    %{
      kind: :negate,
      body: "not",
      expr: Parser.parse(expr, aliases)
    }
  end
end
