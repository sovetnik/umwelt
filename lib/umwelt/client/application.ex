defmodule Umwelt.Client.Application do
  @moduledoc "Client app & Supervisor"

  use Application

  def start(_type, _args) do
    children = [
      {Umwelt.Client.Agent, []},
      {Umwelt.Client.Clone, []}
    ]

    opts = [strategy: :one_for_one, name: Umwelt.Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
