defmodule Umwelt.Client.Clone do
  @moduledoc "Clone main process"

  use GenServer, restart: :transient, shutdown: 10_000
  require Logger

  alias Umwelt.Client

  def start_link(_),
    do:
      GenServer.start_link(
        __MODULE__,
        %{phase_id: nil, port: nil},
        name: __MODULE__
      )

  def init(state), do: {:ok, state}

  def handle_cast({:pull, params}, _state) do
    {:noreply, params, {:continue, :fetch_modules}}
  end

  def handle_continue(:fetch_modules, state) do
    case Client.Request.fetch_modules(state) do
      {:ok, modules} ->
        Logger.info("Fetching modules: #{inspect(Map.keys(modules))}")
        modules |> Client.Agent.add_modules()

      {:error, reason} ->
        Logger.error("Failed to fetch modules: #{inspect(reason)}. Stopping...")
        Supervisor.stop(Client.Supervisor)
    end

    {:noreply, state, {:continue, :start_pulling}}
  end

  def handle_continue(:start_pulling, state) do
    Client.Agent.all_waiting()
    |> Enum.each(fn _ -> spawn_fetcher(state) end)

    {:noreply, state}
  end

  def handle_info({:fetched, %{name: name, code: code}}, state) do
    Client.Agent.update_status(name, :fetched)
    spawn_writer(%{name: name, code: code})
    {:noreply, state}
  end

  def handle_info({:fetch_failed, module}, state) do
    Logger.warning("Respawning failed fetcher for module #{module.name}")
    Client.Fetcher.start_link(module)
    {:noreply, state}
  end

  def handle_info({:written, mod_name}, state) do
    Client.Agent.update_status(mod_name, :written)
    send(self(), :maybe_stop)
    {:noreply, state}
  end

  def handle_info(:maybe_stop, state) do
    if Client.Agent.completed?() do
      Logger.debug("All modules processed. Stopping application.")
      Supervisor.stop(Client.Supervisor)
    end

    {:noreply, state}
  end

  defp spawn_fetcher(state) do
    case Client.Agent.next_waiting() do
      nil ->
        Logger.debug("No more modules to fetch")
        :ok

      module ->
        Logger.debug("Spawning fetcher for module #{inspect(module.name)}")
        Client.Fetcher.start_link(Map.merge(module, state))
    end
  end

  defp spawn_writer(%{name: name} = module) do
    Logger.debug("Spawning writer for module #{inspect(name)}")
    Client.Agent.update_status(name, :writing)
    Client.Writer.start_link(module)
  end
end
