defmodule Umwelt.Files do
  @moduledoc "Finds elixir files recursive from dir"

  def list_from_root(project),
    do: files_in("lib/#{project}")

  def files_in(path) do
    {:ok, files} = File.ls(path)

    files
    |> Enum.map(&extract("#{path}/#{&1}"))
    |> List.flatten()
  end

  defp extract(path) do
    if File.dir?(path) do
      files_in(path)
    else
      path
    end
  end

  # def print(result) do
  #   IO.write(:stdio, inspect(result, pretty: true))
  # end

  #   def save(result) do
  #     File.write!("result.ex", inspect(result))
  #   end
end
