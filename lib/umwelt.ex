defmodule Umwelt do
  @moduledoc """
  Documentation for `Umwelt`.
  """

  alias Umwelt.{Files, Parser}

  def parse_source(project) do
    Map.merge(
      parse_root_source(project),
      parse_other_sources(project)
    )
  end

  def parse_root_source(project) do
    project
    |> Files.root_module()
    |> File.read()
    |> Parser.read_ast()
    |> Parser.parse_root()
  end

  def parse_other_sources(project) do
    project
    |> Files.list_root_dir()
    |> Enum.map(&(&1 |> File.read() |> Parser.read_ast() |> Parser.parse()))
    |> Enum.reduce(&Map.merge/2)
  end
end
