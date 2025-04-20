defmodule Umwelt.ArgumentTest do
  use ExUnit.Case, async: true

  alias Umwelt.Argument

  test "consolidation" do
    assert Argument.__protocol__(:consolidated?)

    assert {:consolidated,
            [
              List,
              Umwelt.Felixir.Call,
              Umwelt.Felixir.Function,
              Umwelt.Felixir.Operator,
              Umwelt.Felixir.Structure,
              Umwelt.Felixir.Variable
            ]} ==
             Argument.__protocol__(:impls)
  end
end
