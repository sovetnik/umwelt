defmodule Umwelt.Client.Writer do
  @moduledoc "File writer task"

  use Task
  require Logger

  alias Umwelt.Client

  def start_link(params) do
    Client.WriterSupervisor
    |> Task.Supervisor.start_child(__MODULE__, :run, [params])
  end

  def run(params) do
    params.code
    |> Enum.each(fn {path, code} -> write_to_file(path, code) end)

    send(Client.Clone, {:written, params.name})
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
