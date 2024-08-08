defmodule Umwelt.Client.Fetcher do
  @moduledoc "Code fetcher task"

  use Task
  require Logger

  alias Umwelt.Client

  def start_link(params) do
    Client.FetcherSupervisor
    |> Task.Supervisor.start_child(__MODULE__, :run, [params])
  end

  def run(params) do
    case Client.Request.fetch_code(params) do
      {:ok, code} ->
        Logger.debug("Success fetch #{params.name}")
        send(Client.Clone, {:fetched, %{name: params.name, code: code}})

      {:error, reason} ->
        Logger.warning("Fail fetch #{params.name}: #{reason}")
        send(Client.Clone, {:fetch_failed, params})
    end
  end
end
