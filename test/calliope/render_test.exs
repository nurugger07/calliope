defmodule CalliopeRenderTest do
  use ExUnit.Case

  import Calliope.Render

  @haml %s{
!!! 5
%section.container{class: "blue"}
  %article
    %h1 Calliope
    / %h1 An important inline comment
    /[if IE]
      %h2 An Elixir Haml Parser
    #main.content
      Welcome to Calliope}

  @html Regex.replace(%r/(^\s*)|(\s+$)|(\n)/m, %s{
    <!DOCTYPE html>
    <section class="container blue">
      <article>
        <h1>Calliope</h1>
        <!-- <h1>An important inline comment</h1> -->
        <!--[if IE]> <h2>An Elixir Haml Parser</h2> <![endif]-->
        <div id="main" class="content">
          Welcome to Calliope
        </div>
      </article>
    </section>
  }, "")

  test :render do
    assert @html == render @haml
  end
end
