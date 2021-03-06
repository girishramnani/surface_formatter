defmodule Surface.Code.FormatterTest do
  use ExUnit.Case

  describe "parse/1" do
    test "adds context to whitespace" do
      surface_code = """
      <div> <p> Hello

      Goodbye </p> </div>
      """

      assert [
               {:whitespace, :indent},
               {"div", [],
                [
                  {:whitespace, :before_child},
                  {"p", [],
                   [
                     {:whitespace, :before_child},
                     "Hello",
                     {:whitespace, :before_whitespace},
                     {:whitespace, :before_child},
                     "Goodbye",
                     {:whitespace, :before_closing_tag}
                   ], _},
                  {:whitespace, :before_closing_tag}
                ], _}
             ] = Surface.Code.Formatter.parse(surface_code)
    end
  end
end
