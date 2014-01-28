defmodule CalliopeRenderTest do
  use ExUnit.Case

  import Calliope.Render

  @haml %s{
%section.container
	%h1 Calliope
	%h2 An Elixir Haml Parser
	#main.content
		Welcome to Calliope}

  @html Regex.replace(%r/(^\s*)|(\s+$)|(\n)/m, %s{
    <section class="container">
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
