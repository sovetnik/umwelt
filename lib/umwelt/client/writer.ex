defmodule Umwelt.Client.Writer do
  @moduledoc "File writer task"

  use Task
  require Logger

  alias Umwelt.Client

  def start_link(module) do
    Task.start_link(__MODULE__, :run, [module])
  end

  def run(module) do
    module.code
    |> Enum.each(fn {path, code} -> write_to_file(path, code) end)

    send(Client.Clone, {:written, module.name})
  end

  defp write_to_file(path, code) do
    path = Path.expand(path, "umwelt_raw")
    path |> Path.dirname() |> File.mkdir_p!()

    case File.read(path) do
      {:ok, content} when content == code ->
        Logger.debug("Write #{path}: identical")

      {:ok, content} ->
        :ok = File.write!(path <> "_", content)
        :ok = File.write!(path, code)
        Logger.debug("Write #{path}: created_with_backup")

      {:error, _reason} ->
        :ok = File.write!(path, code)
        Logger.debug("Write #{path}: created")
    end
  end
end
