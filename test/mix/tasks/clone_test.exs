defmodule Mix.Tasks.CloneTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Mix.Tasks.Umwelt.Clone

  setup do
    bypass = Bypass.open()
    Application.put_env(:umwelt, :api_port, bypass.port)

    :ok = Application.ensure_started(:umwelt)

    on_exit(fn ->
      :timer.sleep(99)
      File.rm_rf!("temp")
    end)

    {:ok, bypass: bypass}
  end

  describe "clone" do
    test "interface call" do
      Application.put_env(:umwelt, :api_token, "no_token")

      assert capture_log([], fn -> assert :ok == Clone.run([42]) end) =~ "Token not found in env!"
    end

    test "success", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/api/trees/23", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"data": {
               "Disco": "1",
               "Disco.Chaos": "2",
               "Disco.Discord": "3"
      }}))
      end)

      Bypass.expect_once(bypass, "GET", "/api/code/23/1", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s({"data": {"temp/lib/disco.ex": "defmodule Disco", 
          "temp/test/disco_test.ex": "defmodule DiscoTest"}})
        )
      end)

      Bypass.expect_once(bypass, "GET", "/api/code/23/2", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s({"data": {"temp/lib/disco/chaos.ex": "defmodule Disco.Chaos", 
          "temp/test/disco/chaos_test.ex": "defmodule Disco.ChaosTest"}})
        )
      end)

      # here we check that fetcher respawns after 401
      Bypass.expect_once(bypass, "GET", "/api/code/23/3", fn conn ->
        Plug.Conn.resp(conn, 401, ~s({"error": "Unauthorized"}))
      end)

      Bypass.expect_once(bypass, "GET", "/api/code/23/3", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s({"data": {"temp/lib/disco/discord.ex": "defmodule Disco.Discord", 
          "temp/test/disco/discord_test.ex": "defmodule Disco.DiscordTest"}})
        )
      end)

      assert capture_log([], fn -> assert :ok == Clone.run([23, "token"]) end) =~ "Done!"

      assert "defmodule Disco" == File.read!("temp/lib/disco.ex")
      assert "defmodule DiscoTest" == File.read!("temp/test/disco_test.ex")
      assert "defmodule Disco.Chaos" == File.read!("temp/lib/disco/chaos.ex")
      assert "defmodule Disco.ChaosTest" == File.read!("temp/test/disco/chaos_test.ex")
      assert "defmodule Disco.Discord" == File.read!("temp/lib/disco/discord.ex")
      assert "defmodule Disco.DiscordTest" == File.read!("temp/test/disco/discord_test.ex")
    end

    test "when fetch unsuccessful", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/api/trees/42", fn conn ->
        Plug.Conn.resp(conn, 401, ~s({"error": "Unauthorized"}))
      end)

      assert capture_log([], fn -> assert :ok == Clone.run([42, "bad_token"]) end) =~
               "Failed to fetch modules: \"Unauthorized\". Stopping..."

      Application.stop(:umwelt)
    end
  end
end
