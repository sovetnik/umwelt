defmodule Umwelt.Parser.Aliases do
  @moduledoc "Parses @attr AST"

  alias Umwelt.Felixir.Alias

  def parse({:alias, _, [{{:., _, [{:__MODULE__, _, nil}, :{}]}, _, _}]}, _, _), do: []

  def parse({:alias, _, [{:__aliases__, _, module}]}, aliases, context),
    do: %Alias{
      name: module_name(module, context),
      path: full_path(module, aliases, context)
    }

  def parse(
        {:alias, _, [{:__aliases__, _, module}, [as: {:__aliases__, _, alias_name}]]},
        aliases,
        context
      ),
      do: %Alias{
        name: module_name(alias_name, context),
        path: full_path(module, aliases, context)
      }

  def parse({:alias, _, [{{:., _, [left, :{}]}, _, children}]}, aliases, context) do
    %{path: left_alias} = parse(left, aliases, context)

    children
    |> Enum.map(fn {:__aliases__, _, right} ->
      %Alias{
        name: module_name(right, context),
        path: stringify_path(left_alias ++ right)
      }
    end)
  end

  def parse({:__aliases__, _, module}, aliases, context) do
    [module_head | _] =
      module_path = module |> expand_module(context) |> stringify_path()

    case Enum.find(aliases, &match?(%{name: ^module_head}, &1)) do
      %{path: path} -> path ++ tl(module_path)
      _ -> module_path
    end
    |> then(&Alias.from_path/1)
  end

  def parse_impl({:__MODULE__, _, nil}, _aliases, context), do: Alias.from_path(context)

  def parse_impl({:__aliases__, _, [head | _] = module}, aliases, _context) do
    head_str = to_string(head)

    case Enum.find(aliases, &match?(%{name: ^head_str}, &1)) do
      %{path: path} -> path
      _ -> stringify_path(module)
    end
    |> then(&Alias.from_path/1)
  end

  def full_path(module, aliases, context) do
    module = module |> expand_module(context)
    [head | rest] = module |> stringify_path()

    case Enum.filter(aliases, &match?(%{name: ^head}, &1)) do
      [] -> module
      [%{path: path}] -> path ++ rest
    end
    |> stringify_path()
  end

  defp module_name(module, context),
    do: module |> expand_module(context) |> List.last() |> to_string

  defp expand_module([{:__MODULE__, _, nil} | rest], context), do: context ++ rest
  defp expand_module(module, _context), do: module
  defp stringify_path(module), do: Enum.map(module, &to_string/1)
end
