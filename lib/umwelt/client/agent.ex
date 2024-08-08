defmodule Umwelt.Client.Agent do
  @moduledoc "Keeps pulling metadata"

  use Agent
  require Logger

  def start_link(_args) do
    Agent.start_link(
      fn ->
        %{
          modules: %{},
          waiting: [],
          fetching: [],
          fetched: [],
          writing: [],
          written: [],
          total: 0
        }
      end,
      name: __MODULE__
    )
  end

  def all_waiting, do: Agent.get(__MODULE__, fn state -> state.waiting end)

  def completed?,
    do: Agent.get(__MODULE__, fn state -> state.total == Enum.count(state.written) end)

  def state, do: Agent.get(__MODULE__, fn state -> state end)
  def total, do: Agent.get(__MODULE__, fn state -> state.total end)
  def ready, do: Agent.get(__MODULE__, fn state -> Enum.count(state.written) end)

  def add_modules(modules) do
    Agent.update(__MODULE__, fn state ->
      %{
        state
        | modules: modules,
          waiting: Map.keys(modules),
          fetching: [],
          fetched: [],
          writing: [],
          written: [],
          total: map_size(modules)
      }
    end)
  end

  def next_waiting do
    Agent.get_and_update(__MODULE__, fn state ->
      case state.waiting do
        [mod_name | modules] ->
          {
            %{id: state.modules[mod_name], name: mod_name},
            state
            |> Map.put(:waiting, modules)
            |> Map.put(:fetching, [mod_name | state.fetching])
          }

        [] ->
          {nil, state}
      end
    end)
  end

  def update_status(mod_name, :fetched) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.put(:fetching, List.delete(state.fetching, mod_name))
      |> Map.put(:fetched, [mod_name | state.fetched])
    end)
  end

  def update_status(mod_name, :writing) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.put(:writing, [mod_name | state.writing])
    end)
  end

  def update_status(mod_name, :written) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.put(:writing, List.delete(state.writing, mod_name))
      |> Map.put(:written, [mod_name | state.written])
    end)

    render_progress()
  end

  def render_progress do
    ProgressBar.render(ready(), total(), suffix: :count)
  end
end
