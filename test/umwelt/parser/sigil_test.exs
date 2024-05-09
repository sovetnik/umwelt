defmodule Umwelt.Parser.SigilTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Sigil

  import Umwelt.Parser.Sigil,
    only: [is_sigil: 1]

  describe "guards" do
    test "guard is_sigil" do
      [
        :sigil_C,
        :sigil_c,
        :sigil_D,
        :sigil_N,
        :sigil_R,
        :sigil_r,
        :sigil_S,
        :sigil_s,
        :sigil_T,
        :sigil_U,
        :sigil_W,
        :sigil_w
      ]
      |> Enum.map(&assert is_sigil(&1))
    end
  end

  describe "Charlist" do
    test "without interpolations and without escape characters" do
      {:ok, ast} = Code.string_to_quoted("~C(f#\{o\}o)")

      assert %{body: "f\#{o}o", note: "sigil_C(", kind: :Sigil} ==
               Sigil.parse(ast, [])
    end

    test "as if it was a single quoted string" do
      {:ok, ast} = Code.string_to_quoted("~c(f\#\{:o\}o)")

      assert %{body: "f\#{:o}o", note: "sigil_c(", kind: :Sigil} == Sigil.parse(ast, [])
    end
  end

  describe "Date & Time in the ISO8601 format" do
    test "Date from built-in Calendar.ISO" do
      {:ok, ast} = Code.string_to_quoted("~D[2015-01-13]")

      assert %{body: "2015-01-13", note: "sigil_D[", kind: :Sigil} ==
               Sigil.parse(ast, [])
    end

    test "Naive datetime" do
      {:ok, ast} = Code.string_to_quoted("~N[2015-01-13 13:00:07]")

      assert %{body: "2015-01-13 13:00:07", note: "sigil_N[", kind: :Sigil} ==
               Sigil.parse(ast, [])
    end

    test "Time" do
      {:ok, ast} = Code.string_to_quoted("~T[13:00:07.001]")

      assert %{
               body: "13:00:07.001",
               note: "sigil_T[",
               kind: :Sigil
             } == Sigil.parse(ast, [])
    end

    test "UTC date times" do
      {:ok, ast} = Code.string_to_quoted("~U[2015-01-13T13:00:07.001+00:00]")

      assert %{
               body: "2015-01-13T13:00:07.001+00:00",
               note: "sigil_U[",
               kind: :Sigil
             } == Sigil.parse(ast, [])
    end
  end

  describe "String" do
    test "without interpolations and without escape characters" do
      {:ok, ast} = Code.string_to_quoted("~S|f#\{o\}o|")

      assert %{body: "f\#{o}o", note: "sigil_S|", kind: :Sigil} == Sigil.parse(ast, [])
    end

    test "unescaping characters and replacing interpolations" do
      {:ok, ast} = Code.string_to_quoted("~s(f\#{:o}o)")

      assert %{
               body: "f\#{:o}o",
               kind: :Sigil,
               note: "sigil_s("
             } == Sigil.parse(ast, [])
    end
  end

  describe "Wordlist" do
    test "sigil W" do
      {:ok, ast} = Code.string_to_quoted("~w|foo bar|a")

      assert %{
               body: "foo bar",
               note: "sigil_w|a",
               kind: :Sigil
             } == Sigil.parse(ast, [])
    end
  end

  describe "Regex" do
    test "sigil r simple" do
      {:ok, ast} = Code.string_to_quoted("~r/foo/")

      assert %{
               body: "foo",
               note: "sigil_r/",
               kind: :Sigil
             } == Sigil.parse(ast, [])
    end

    test "still thinking about complex regex" do
      {:ok, ast} = Code.string_to_quoted("~r/a#{:b}c/")

      assert %{
               body: "abc",
               note: "sigil_r/",
               kind: :Sigil
             } == Sigil.parse(ast, [])
    end
  end
end
