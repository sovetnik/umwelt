defmodule Umwelt.Client.RequestTest do
  use ExUnit.Case

  alias Bypass
  alias Umwelt.Client.Request

  setup do
    bypass = Bypass.open()
    :ok = Application.ensure_started(:umwelt)

    {:ok, bypass: bypass}
  end

  test "fetch_modules returns modules", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"data": {
               "Disco": "1",
               "Disco.Chaos": "2",
               "Disco.Discord": "3"
      }}))
    end)

    assert {:ok,
            %{
              "Disco" => "1",
              "Disco.Chaos" => "2",
              "Disco.Discord" => "3"
            }} ==
             Request.fetch_modules(%{
               api_host: "http://localhost",
               phase_id: 1,
               port: bypass.port,
               token: "token"
             })
  end

  test "fetch_code returns code files", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"data": {"foo.ex": "code1", "foo_spec.exs": "code2"}}))
    end)

    assert {:ok, %{"foo.ex" => "code1", "foo_spec.exs" => "code2"}} ==
             Request.fetch_code(%{
               api_host: "http://localhost",
               id: 23,
               phase_id: 5,
               port: bypass.port,
               token: "token"
             })
  end
end
