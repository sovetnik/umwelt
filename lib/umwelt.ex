defmodule Umwelt do
  @moduledoc """
  Documentation for `Umwelt`.
  """

  alias Umwelt.Files
  alias Umwelt.Parser

  def parse_source(project) do
    Files.list_from_root(project)
    |> Enum.map(fn
      filename ->
        filename
        |> File.read()
        |> Parser.read_ast()
        |> Parser.parse()
    end)
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(map, acc)
    end)
  end
end
