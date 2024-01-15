defmodule Umwelt.Files do
  @moduledoc "Finds elixir files recursive from dir"

  def list_from_root(project \\ Mix.Project.config()[:app]) do
    Mix.Project.config()[:elixirc_paths]
    |> Enum.flat_map(&files_in(Path.join(&1, to_string(project))))
  end

  def files_in(path), do: path |> File.dir?() |> do_files_in(path)

  defp do_files_in(false, path), do: [path]

  defp do_files_in(true, path) do
    with {:ok, files} <- File.ls(path),
         do: Enum.flat_map(files, &files_in(Path.join(path, &1)))
  end
end
