defmodule Umwelt.Parser.Aliases do
  @moduledoc "Parses @attr AST"

  def parse({:alias, _, [{:__aliases__, _, module}]}, aliases, context),
    do: %{
      kind: :Alias,
      name: module_name(module, context),
      path: full_path(module, aliases, context)
    }

  def parse(
        {:alias, _, [{:__aliases__, _, module}, [as: {:__aliases__, _, alias_name}]]},
        aliases,
        context
      ),
      do: %{
        kind: :Alias,
        name: module_name(alias_name, context),
        path: full_path(module, aliases, context)
      }

  def parse({:alias, _, [{{:., _, [left, :{}]}, _, children}]}, aliases, context) do
    %{path: left_alias} = parse(left, aliases, context)

    children
    |> Enum.map(fn {:__aliases__, _, right} ->
      %{
        kind: :Alias,
        name: module_name(right, context),
        path: stringify_path(left_alias ++ right)
      }
    end)
  end

  def parse({:__aliases__, _, module}, aliases, context),
    do: %{
      kind: :Alias,
      name: module_name(module, context),
      path: full_path(module, aliases, context)
    }

  def full_path(module, [], context),
    do: module |> expand_module(context) |> stringify_path()

  def full_path(module, aliases, context) do
    module = module |> expand_module(context)
    [head | rest] = module |> stringify_path()

    case Enum.filter(aliases, &match?(%{name: ^head}, &1)) do
      [] ->
        module

      [%{path: path}] ->
        path ++ rest
    end
    |> stringify_path()
  end

  defp module_name(module, context),
    do: module |> expand_module(context) |> List.last() |> to_string

  defp expand_module([{:__MODULE__, _, nil} | rest], context), do: context ++ rest
  defp expand_module(module, _context), do: module
  defp stringify_path(module), do: Enum.map(module, &to_string/1)
end
