defmodule Mix.Tasks.Umwelt.Clone do
  @moduledoc "Clones phase modules and code"
  @shortdoc "The code puller"
  use Mix.Task
  require Logger

  @impl Mix.Task
  def run([phase_id]) do
    case System.get_env("UMWELT_TOKEN", "no_token") do
      "no_token" ->
        """
        Token not found in env!
        You can get it on umwelt.dev/auth/profile and do 

          export UMWELT_TOKEN="token"

        or pass it directly in 

          mix clone phase_id "token"

        """
        |> Logger.warning()

      token ->
        run([phase_id, token])
    end
  end

  @impl Mix.Task
  def run([phase_id, token]) do
    Umwelt.Client.Application.start(nil, nil)

    Umwelt.Client.Supervisor
    |> Process.whereis()
    |> Process.monitor()

    %{phase_id: phase_id, token: token}
    |> assign_host()
    |> assign_port()
    |> Umwelt.Client.pull()

    receive do
      {:DOWN, _, :process, _, _} ->
        Logger.info("Done!")

      other ->
        Logger.warning(inspect(other))
    end
  end

  defp assign_host(params) do
    host =
      case Mix.env() do
        :dev ->
          System.get_env("UMWELT_HOST", "https://umwelt.dev")

        :test ->
          "http://localhost"
      end

    Map.put(params, :api_host, host)
  end

  defp assign_port(params) do
    port =
      case Mix.env() do
        :dev ->
          case params.api_host do
            "http://localhost" -> 4000
            "https://umwelt.dev" -> 443
          end

        :test ->
          Application.get_env(:umwelt, :api_port)
      end

    Map.put(params, :port, port)
  end
end
