defmodule Umwelt.Client.Fetcher do
  @moduledoc "Code fetcher task"

  use Task
  require Logger

  alias Umwelt.Client

  def start_link(module) do
    Task.start_link(__MODULE__, :run, [module])
  end

  def run(module) do
    case Client.Request.fetch_code(module) do
      {:ok, code} ->
        Logger.debug("Success fetch #{module.name}")
        send(Client.Clone, {:fetched, %{name: module.name, code: code}})

      {:error, reason} ->
        Logger.warning("Fail fetch #{module.name}: #{reason}")
        send(Client.Clone, {:fetch_failed, module})
    end
  end
end
