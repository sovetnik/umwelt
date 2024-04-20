defmodule Umwelt.Files do
  @moduledoc "Finds elixir files recursive from dir"

  @elixirc_paths Mix.Project.config()[:elixirc_paths]

  def root_module(project) do
    @elixirc_paths
    |> Enum.flat_map(&filter_root_files(&1, project))
  end

  def list_root_dir(project) do
    @elixirc_paths
    |> Enum.flat_map(&files_in(Path.join(&1, to_string(project))))
  end

  defp filter_root_files(path, project) do
    {:ok, regex} = Regex.compile("#{project}.ex")

    with {:ok, files} <- File.ls(path),
         do:
           files
           |> Enum.reject(&File.dir?(Path.join(path, &1)))
           |> Enum.filter(&String.match?(&1, regex))
           |> Enum.map(&Path.join(path, &1))
  end

  defp files_in(path),
    do: path |> File.dir?() |> do_files_in(path)

  defp do_files_in(false, path), do: [path]

  defp do_files_in(true, path) do
    with {:ok, files} <- File.ls(path),
         do: Enum.flat_map(files, &files_in(Path.join(path, &1)))
  end
end
