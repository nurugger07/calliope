defmodule CalliopeRenderTest do
  use ExUnit.Case

  import Calliope.Render

  @haml_div "%div Hello Calliope"

  test "render a div with inline content" do
    assert "<div>Hello Calliope</div>" == render(@haml_div)
  end
end
