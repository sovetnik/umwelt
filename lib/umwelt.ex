defmodule Umwelt do
  @moduledoc """
  Documentation for `Umwelt`.
  """

  alias Umwelt.{Files, Parser}

  def parse_source(project) do
    project
    |> Files.list_from_root()
    |> Enum.map(&(&1 |> File.read() |> Parser.read_ast() |> Parser.parse()))
    |> Enum.reduce(&Map.merge/2)
  end
end
