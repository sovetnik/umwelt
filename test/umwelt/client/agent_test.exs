defmodule Umwelt.Client.AgentTest do
  use ExUnit.Case

  alias Umwelt.Client.Agent

  setup do
    modules = %{
      "Discordian" => 248_169,
      "Discordian.Aftermath" => 248_188,
      "Discordian.Bureaucracy" => 248_187,
      "Discordian.Chaos" => 248_184,
      "Discordian.Confusion" => 248_186,
      "Discordian.Discord" => 248_185
    }

    :ok = Application.ensure_started(:umwelt)

    {:ok, modules: modules}
  end

  test "initial state is empty", _context do
    assert %{
             modules: %{},
             waiting: [],
             fetching: [],
             fetched: [],
             writing: [],
             written: [],
             total: 0
           } == Agent.state()
  end

  test "add_modules/1 adds modules to state", %{modules: modules} do
    Agent.add_modules(modules)

    assert %{
             modules: modules,
             waiting: Map.keys(modules),
             fetching: [],
             fetched: [],
             writing: [],
             written: [],
             total: 6
           } == Agent.state()

    Agent.add_modules(%{})
  end

  describe "next_waiting/0" do
    test "retrieves and updates the state correctly", %{modules: modules} do
      Agent.add_modules(modules)

      assert Agent.next_waiting() == %{id: 248_169, name: "Discordian"}

      assert %{
               modules: modules,
               waiting: Map.keys(modules) -- ["Discordian"],
               fetching: ["Discordian"],
               fetched: [],
               writing: [],
               written: [],
               total: 6
             } == Agent.state()

      Agent.add_modules(%{})
    end

    test "when waiting list is already empty" do
      Agent.add_modules(%{"Discordian" => 248_169})

      assert Agent.next_waiting() == %{id: 248_169, name: "Discordian"}

      assert %{
               modules: %{"Discordian" => 248_169},
               waiting: [],
               fetching: ["Discordian"],
               fetched: [],
               writing: [],
               written: [],
               total: 1
             } == Agent.state()

      assert Agent.next_waiting() == nil

      assert %{
               modules: %{"Discordian" => 248_169},
               waiting: [],
               fetching: ["Discordian"],
               fetched: [],
               writing: [],
               written: [],
               total: 1
             } == Agent.state()

      Agent.add_modules(%{})
    end
  end

  describe "update_status/2" do
    test "updates the module status to :fetched", %{modules: modules} do
      Agent.add_modules(modules)
      Agent.next_waiting()

      Agent.update_status("Discordian", :fetched)
      state = Agent.state()
      assert state.fetching == []
      assert state.fetched == ["Discordian"]
      Agent.add_modules(%{})
    end

    test "updates the module status to :writing", %{modules: modules} do
      Agent.add_modules(modules)
      Agent.next_waiting()
      Agent.update_status("Discordian", :fetched)

      Agent.update_status("Discordian", :writing)
      state = Agent.state()
      assert state.writing == ["Discordian"]
      Agent.add_modules(%{})
    end

    test "updates the module status to :written", %{modules: modules} do
      Agent.add_modules(modules)
      Agent.next_waiting()
      Agent.update_status("Discordian", :fetched)
      Agent.update_status("Discordian", :writing)

      Agent.update_status("Discordian", :written)
      state = Agent.state()
      assert state.writing == []
      assert state.written == ["Discordian"]
      Agent.add_modules(%{})
    end
  end

  describe "completed?/0" do
    test "returns true when all modules are written", %{modules: modules} do
      Agent.add_modules(modules)

      for module_name <- Map.keys(modules) do
        Agent.next_waiting()
        Agent.update_status(module_name, :fetched)
        Agent.update_status(module_name, :writing)
        Agent.update_status(module_name, :written)
      end

      assert Agent.completed?()
      Agent.add_modules(%{})
    end

    test "returns false when not all modules are written", %{modules: modules} do
      Agent.add_modules(modules)

      for module_name <- Enum.take(Map.keys(modules), 3) do
        Agent.next_waiting()
        Agent.update_status(module_name, :fetched)
        Agent.update_status(module_name, :writing)
        Agent.update_status(module_name, :written)
      end

      refute Agent.completed?()
      Agent.add_modules(%{})
    end
  end
end
