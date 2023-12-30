defmodule Umwelt.Parser.Struct do
  @moduledoc "Parses %Struct{} AST"

  def parse({:%, _, [{:__aliases__, _, module}, {:%{}, _, []}]}, aliases),
    do: expand_module(module, aliases)

  defp expand_module(module, []), do: module

  defp expand_module([head | rest], aliases) do
    aliases
    |> Enum.filter(&match?([^head | _], Enum.reverse(&1)))
    |> List.flatten()
    |> Kernel.++(rest)
  end
end
