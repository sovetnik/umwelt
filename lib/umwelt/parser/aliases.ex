defmodule Umwelt.Parser.Aliases do
  @moduledoc "Parses @attr AST"

  def parse({:alias, _, [{:__aliases__, _, module}]}, aliases),
    do: %{kind: :Alias, name: module_name(module), path: expand_module(module, aliases)}

  def parse(
        {:alias, _, [{:__aliases__, _, module}, [as: {:__aliases__, _, alias_name}]]},
        aliases
      ),
      do: %{kind: :Alias, name: module_name(alias_name), path: expand_module(module, aliases)}

  def parse({:alias, _, [{{:., _, [left, :{}]}, _, children}]}, aliases) do
    %{path: left_alias} = parse(left, aliases)

    children
    |> Enum.map(fn {:__aliases__, _, right} ->
      %{
        kind: :Alias,
        name: module_name(right),
        path: stringify_path(left_alias ++ right)
      }
    end)
  end

  def parse({:__aliases__, _, module}, aliases),
    do: %{kind: :Alias, name: module_name(module), path: expand_module(module, aliases)}

  def expand_module(module, []),
    do: module |> stringify_path()

  def expand_module(module, aliases) do
    [head | rest] = module |> stringify_path()

    # matched_aliases = Enum.filter(aliases, &match?(%{name: ^head}, &1))

    case Enum.filter(aliases, &match?(%{name: ^head}, &1)) do
      [] ->
        module

      [%{path: path}] ->
        path ++ rest
    end
    |> stringify_path()
  end

  defp module_name(module) do
    module |> List.last() |> to_string
  end

  defp stringify_path(module) do
    Enum.map(module, &to_string/1)
  end
end
