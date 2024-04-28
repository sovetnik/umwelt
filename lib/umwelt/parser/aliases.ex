defmodule Umwelt.Parser.Aliases do
  @moduledoc "Parses @attr AST"

  def parse({:alias, _, [{:__aliases__, _, module}]}, aliases) do
    [expand_module(module, aliases)]
    %{kind: :Alias, name: List.last(module), path: expand_module(module, aliases)}
  end

  def parse(
        {:alias, _, [{:__aliases__, _, module}, [as: {:__aliases__, _, short_alias}]]},
        aliases
      ) do
    %{kind: :Alias, name: short_alias, path: expand_module(module, aliases)}
  end

  def parse({:alias, _, [{{:., _, [left, :{}]}, _, children}]}, aliases) do
    %{path: left_alias} = parse(left, aliases)

    children
    |> Enum.map(fn {:__aliases__, _, right} ->
      %{
        kind: :Alias,
        name: List.last(right),
        path: left_alias ++ right
      }
    end)
  end

  def parse({:__aliases__, _, module}, aliases) do
    %{kind: :Alias, name: List.last(module), path: expand_module(module, aliases)}
  end

  def expand_module(module, []), do: module

  def expand_module([head | rest] = module, aliases) do
    matched_aliases =
      aliases
      |> Enum.filter(&match?(%{name: ^head}, &1))

    case matched_aliases do
      [] ->
        module

      [%{path: path}] ->
        path ++ rest
    end
  end
end
