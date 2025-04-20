defmodule Umwelt.Parser.SigilTest do
  use ExUnit.Case, async: true

  alias Umwelt.Felixir.Sigil
  alias Umwelt.Parser

  import Umwelt.Parser.Sigil, only: [is_sigil: 1]

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

      assert %Sigil{string: "f\#{o}o", mod: "sigil_C("} ==
               Parser.Sigil.parse(ast, [])
    end

    test "as if it was a single quoted string" do
      {:ok, ast} = Code.string_to_quoted("~c(f\#\{:o\}o)")

      assert %Sigil{string: "f\#{:o}o", mod: "sigil_c("} == Parser.Sigil.parse(ast, [])
    end
  end

  describe "Date & Time in the ISO8601 format" do
    test "Date from built-in Calendar.ISO" do
      {:ok, ast} = Code.string_to_quoted("~D[2015-01-13]")

      assert %Sigil{string: "2015-01-13", mod: "sigil_D["} ==
               Parser.Sigil.parse(ast, [])
    end

    test "Naive datetime" do
      {:ok, ast} = Code.string_to_quoted("~N[2015-01-13 13:00:07]")

      assert %Sigil{string: "2015-01-13 13:00:07", mod: "sigil_N["} ==
               Parser.Sigil.parse(ast, [])
    end

    test "Time" do
      {:ok, ast} = Code.string_to_quoted("~T[13:00:07.001]")

      assert %Sigil{
               string: "13:00:07.001",
               mod: "sigil_T["
             } == Parser.Sigil.parse(ast, [])
    end

    test "UTC date times" do
      {:ok, ast} = Code.string_to_quoted("~U[2015-01-13T13:00:07.001+00:00]")

      assert %Sigil{
               string: "2015-01-13T13:00:07.001+00:00",
               mod: "sigil_U["
             } == Parser.Sigil.parse(ast, [])
    end
  end

  describe "String" do
    test "without interpolations and without escape characters" do
      {:ok, ast} = Code.string_to_quoted("~S|f#\{o\}o|")

      assert %Sigil{string: "f\#{o}o", mod: "sigil_S|"} == Parser.Sigil.parse(ast, [])
    end

    test "unescaping characters and replacing interpolations" do
      {:ok, ast} = Code.string_to_quoted("~s(f\#{:o}o)")

      assert %Sigil{
               string: "f\#{:o}o",
               mod: "sigil_s("
             } == Parser.Sigil.parse(ast, [])
    end
  end

  describe "Wordlist" do
    test "sigil W" do
      {:ok, ast} = Code.string_to_quoted("~w|foo bar|a")

      assert %Sigil{
               string: "foo bar",
               mod: "sigil_w|a"
             } == Parser.Sigil.parse(ast, [])
    end
  end

  describe "Regex" do
    test "sigil r simple" do
      {:ok, ast} = Code.string_to_quoted("~r/foo/")

      assert %Sigil{
               string: "foo",
               mod: "sigil_r/"
             } == Parser.Sigil.parse(ast, [])
    end

    test "still thinking about complex regex" do
      {:ok, ast} = Code.string_to_quoted("~r/a#{:b}c/")

      assert %Sigil{
               string: "abc",
               mod: "sigil_r/"
             } == Parser.Sigil.parse(ast, [])
    end
  end
end
