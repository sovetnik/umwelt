defmodule Umwelt.Client.WriterTest do
  use ExUnit.Case

  alias Umwelt.Client.{Agent, Writer}

  setup do
    module = %{
      code: %{
        "temp/lib/disco/chaos.ex" => "defmodule Disco.Chaos",
        "temp/test/disco/chaos_test.exs" => "defmodule Disco.ChaosTest"
      },
      name: "Disco.Chaos"
    }

    :ok = Application.ensure_started(:umwelt)

    Agent.add_modules(%{"Disco.Chaos" => 23})
    Agent.update_status("Disco.Chaos", :fetched)

    on_exit(fn -> File.rm_rf!("umwelt_raw/temp") end)

    {:ok, module: module}
  end

  describe "run/1" do
    test "writes new files correctly", %{module: module} do
      lib_path = "umwelt_raw/temp/lib/disco/chaos.ex"
      test_path = "umwelt_raw/temp/test/disco/chaos_test.exs"

      log = capture_log(fn -> Writer.run(module) end)

      :timer.sleep(666)
      assert log =~ " #{Path.expand(lib_path)}: created"
      assert log =~ " #{Path.expand(test_path)}: created"

      assert File.read!(lib_path) == "defmodule Disco.Chaos"
      assert File.read!(test_path) == "defmodule Disco.ChaosTest"
    end

    test "writes identical files correctly", %{module: module} do
      lib_path = "umwelt_raw/temp/lib/disco/chaos.ex"
      test_path = "umwelt_raw/temp/test/disco/chaos_test.exs"

      File.mkdir_p!(Path.dirname(lib_path))
      File.write!(lib_path, "defmodule Disco.Chaos")
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, "defmodule Disco.ChaosTest")

      log = capture_log(fn -> Writer.run(module) end)

      assert log =~ " #{Path.expand(lib_path)}: identical"
      assert log =~ " #{Path.expand(test_path)}: identical"
    end

    test "creates backup and writes new content", %{module: module} do
      lib_path = "umwelt_raw/temp/lib/disco/chaos.ex"
      test_path = "umwelt_raw/temp/test/disco/chaos_test.exs"
      lib_backup_path = "#{lib_path}_"
      test_backup_path = "#{test_path}_"

      File.mkdir_p!(Path.dirname(lib_path))
      File.write!(lib_path, "old lib content")
      File.mkdir_p!(Path.dirname(test_path))
      File.write!(test_path, "old test content")

      log = capture_log(fn -> Writer.run(module) end)

      assert log =~ "#{Path.expand(lib_path)}: created_with_backup"
      assert log =~ "#{Path.expand(test_path)}: created_with_backup"

      assert File.read!(lib_path) == "defmodule Disco.Chaos"
      assert File.read!(test_path) == "defmodule Disco.ChaosTest"
      assert File.read!(lib_backup_path) == "old lib content"
      assert File.read!(test_backup_path) == "old test content"
    end
  end

  defp capture_log(fun) do
    ExUnit.CaptureLog.capture_log(fn -> fun.() end)
  end
end
