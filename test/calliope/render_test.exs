defmodule CalliopeRenderTest do
  use ExUnit.Case

  import Calliope.Render

  @haml ~s{
!!! 5
%section.container{class: "blue"}
  %article
    %h1= title
    / %h1 An important inline comment
    /[if IE]
      %h2 An Elixir Haml Parser
    #main.content
      Welcome to Calliope}

  @html Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
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

  @haml_with_args "%a{href: url}= title"

  @posts [
    { 1, "One Great Article!", "This is some great content." },
    { 2, "Another Great Article", "These articles just keep coming." }
  ]

  @haml_with_collection """
- lc { id, subject, content } inlist posts do
  %article.post
    %h1
      %a{href: "/posts/\#{id}"}= subject
    = content
  """

  @html_with_collection Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
  <article class="post">
    <h1><a href="/posts/1">One Great Article!</a></h1>
    <p>
      This is some great content.
    </p>
  </article>
  <article class="post">
    <h1><a href="/posts/2">Another Great Article</a></h1>
    <p>
      These articles just keep coming.
    </p>
  </article>}, "")

  test :render do
    assert @html == render @haml, [title: "Calliope"]
    assert "<h1>This is Calliope</h1>" == render "%h1 This is \#{title}", [title: "Calliope"]
  end

  test :render_with_params do
    assert "<a href='http://google.com'>Google</a>" ==
      render @haml_with_args, [ url: "http://google.com", title: "Google" ]
  end

  # test :render_with_collection do
  #   assert @html_with_collection == render @haml_with_collection, [posts: @posts]
  # end
end
