defmodule Mix.Tasks.Dump do
  @moduledoc "This task for self-parse umwelt"
  @shortdoc "The lib parser"

  use Mix.Task

  @impl Mix.Task
  def run([]), do: parse_into("umwelt.bin")
  def run([filename]), do: parse_into(filename)

  defp parse_into(filename) do
    Mix.Project.config()[:app]
    |> to_string()
    |> Umwelt.Parser.parse_source()
    |> :erlang.term_to_binary()
    |> dump(filename)

    Mix.shell().info("Parsing result saved into #{filename}")
  end

  defp dump(result, filename), do: File.write(filename, result)
end
