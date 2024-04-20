defmodule Umwelt.Parser.Aliases do
  @moduledoc "Parses @attr AST"

  def parse({:alias, _, [{:__aliases__, _, module}]}, aliases) do
    [expand_module(module, aliases)]
  end

  def parse({:alias, _, [{{:., _, [left, :{}]}, _, children}]}, aliases) do
    [left_alias] = parse(left, aliases)

    children
    |> Enum.map(fn ast -> [left_alias | parse(ast, [])] end)
  end

  def parse({:__aliases__, _, module}, aliases) do
    expand_module(module, aliases)
  end

  def expand_module(module, []), do: module

  def expand_module([head | rest], aliases) do
    aliases
    |> Enum.filter(&match?([^head | _], Enum.reverse(&1)))
    |> List.flatten()
    |> Kernel.++(rest)
  end
end
