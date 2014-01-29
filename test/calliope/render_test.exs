defmodule CalliopeRenderTest do
  use ExUnit.Case

  import Calliope.Render

  @haml %s{
!!! 5
%section.container{ class: "blue" }
	%h1 Calliope
	%h2 An Elixir Haml Parser
	#main.content
		Welcome to Calliope}

  @html Regex.replace(%r/(^\s*)|(\s+$)|(\n)/m, %s{
    <!DOCTYPE html>
    <section class="container blue">
      <h1>Calliope</h1>
      <h2>An Elixir Haml Parser</h2>
      <div id="main" class="content">
        Welcome to Calliope
      </div>
    </section>
  }, "")

  test :render do
    assert @html == render @haml
  end

end
