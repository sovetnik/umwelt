defmodule Umwelt.Client do
  @moduledoc "Client for umwelt.dev"

  alias Umwelt.Client.Clone

  require Logger

  def pull(params) do
    GenServer.cast(Clone, {:pull, params})
  end
end
