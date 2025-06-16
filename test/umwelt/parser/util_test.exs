defmodule Umwelt.Parser.UtilTest do
  use ExUnit.Case, async: true

  alias Umwelt.Parser.Util

  test "string" do
    assert "foo" == Util.string_or("foo", "bar")
  end

  test "multiline string" do
    assert "boogie\nwoogie\n" ==
             """
             boogie
             woogie
             """
             |> Util.string_or("moogy")
  end

  test "long string" do
    assert "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque urna quis nibh ornare, id pulvinar urna lobortis. Ut vel justo sit amet elit porta efficitur ac id ipsum. Pellentesque porta tempus odio, ut scelerisque metus condimentum ut...." ==
             """
             Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus scelerisque urna quis nibh ornare, id pulvinar urna lobortis. Ut vel justo sit amet elit porta efficitur ac id ipsum. Pellentesque porta tempus odio, ut scelerisque metus condimentum ut. Suspendisse nec dolor odio. Ut facilisis viverra accumsan. Nulla quis nulla ut ante luctus rutrum. 
             """
             |> Util.string_or("bar")
  end

  test "not a string" do
    assert "bar" == Util.string_or(nil, "bar")
  end
end
