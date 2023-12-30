defmodule Mix.Tasks.Parse do
  @moduledoc "This task for self-parse umwelt"
  @shortdoc "The lib parser"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    Mix.Project.config()[:app]
    |> to_string()
    |> Umwelt.parse_source()
    |> print()
  end

  defp print(result),
    do: IO.write(:stdio, inspect(result, pretty: true))
end
