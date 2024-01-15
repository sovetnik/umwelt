defmodule Umwelt.Parser.Comparsion do
  @moduledoc "Parses Comparsion AST"

  alias Umwelt.Parser

  defguard is_comparsion_operator(term)
           when term in [:==, :!=, :===, :!==, :<, :<=, :>, :>=]

  defguard is_strict_bool_comparsion(term)
           when term in [:and, :or, :not, :in]

  defguard is_relaxed_bool_comparsion(term)
           when term in [:&&, :||, :!]

  defguard is_comparsion(term)
           when is_comparsion_operator(term) or
                  is_strict_bool_comparsion(term) or
                  is_relaxed_bool_comparsion(term)

  def parse({:in, _, [left, right]}, aliases) when is_list(right) do
    %{
      kind: :inclusion,
      body: "inclusion",
      left: Parser.parse(left, aliases),
      right: Parser.parse(right, aliases)
    }
  end

  def parse({term, _, [left, right]}, aliases)
      when is_comparsion(term) do
    %{
      kind: :comparsion,
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
