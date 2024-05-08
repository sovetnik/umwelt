defmodule Mix.Tasks.Dump do
  @moduledoc "This task for self-parse umwelt"
  @shortdoc "The lib parser"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    parse_into("#{Mix.Project.config()[:app]}.bin")
  end

  def run([filename]), do: parse_into(filename)

  defp parse_into(filename) do
    binary =
      Mix.Project.config()[:app]
      |> to_string()
      |> Umwelt.Parser.parse_source()
      |> :erlang.term_to_binary()

    Mix.shell().info("Binary size #{byte_size(binary)}")

    case dump(binary, filename) do
      :ok ->
        Mix.shell().info("Parsing result saved into #{filename}")

      _ ->
        Mix.shell().error("Something went wrong")
    end
  end

  defp dump(result, filename), do: File.write(filename, result)
end
