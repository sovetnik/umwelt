defmodule Mix.Tasks.Umwelt.Dump do
  @moduledoc "This task for self-parse umwelt"
  @shortdoc "The lib parser"

  use Mix.Task

  @impl Mix.Task
  def run([]) do
    Mix.Project.config()[:app]
    |> to_string()
    |> parse_to_bin()
  end

  def run([root_name]), do: parse_to_bin(root_name)

  defp parse_to_bin(name) do
    binary =
      name
      |> Umwelt.Parser.parse_source()
      |> :erlang.term_to_binary()

    Mix.shell().info("Binary size #{byte_size(binary)}")

    case dump(binary, filename(name)) do
      :ok ->
        Mix.shell().info("Parsing result saved into #{filename(name)}")

      _ ->
        Mix.shell().error("Something went wrong")
    end
  end

  defp dump(result, filename), do: File.write(filename, result)

  defp filename(root_name) do
    "#{root_name}.bin"
  end
end
