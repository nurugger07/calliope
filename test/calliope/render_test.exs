defmodule CalliopeRenderTest do
  use ExUnit.Case

  use Calliope.Render
  import Support.EquivalentHtml

  def haml_with_args, do: "%a{href: '#\{url}'}= title"
  def haml_with_unin_args, do: "%a{href: url}= title"
  def haml_with_unin_args_content_only, do: "%a{href: url} title"
  def haml_with_unin_parens, do: "%a(href=url)= title"

  test :render do
    assert "<h1>This is <%= title %></h1>\n" == render "%h1 This is \#{title}"
    assert "<a ng-click='doSomething()'>Click Me</a>\n" == render "%a{ng-click: 'doSomething()'} Click Me"
    assert "<h1>{{user}}</h1>\n" == render "%h1 {{user}}"
  end

  test :render_document do
    expected = """
      <!DOCTYPE html>
      <section class="container blue" style="margin-top: 10px" data-value='<%= @value %>'>
        <article>
          <h1><%= title %></h1>
          <script type="text/javascript">
            var x = 5;
            var y = 10;
          </script>
          <!-- <h1>An important inline comment</h1> -->
          <!--[if IE]><h2>An Elixir Haml Parser</h2><![endif]-->
          <label class="cl1 cl2" for="test">Label</label>
          <div id="main" class="content">
            Welcome to Calliope
          </div>
        </article>
      </section>
      """

    haml = """
      !!! 5
      %section.container(class= "blue" style="margin-top: 10px" data-value=@value)
        %article
          %h1= title
          :javascript
            var x = 5;
            var y = 10;
          / %h1 An important inline comment
          /[if IE]
            %h2 An Elixir Haml Parser
          %label.cl1\{ for:  "test", class: " cl2"  \} Label
          #main.content
            Welcome to Calliope
      """
    assert_equivalent_html(expected, render(haml))
  end

  test :render_indented_plain_args do
    expected = """
      <a href='http://foobar.com'>Text</a>
      """

    haml = """
      %a{href: url} Text
      """
    assert_equivalent_html(expected, render(haml, [url: 'http://foobar.com']))
  end

  test :eval do
    result = "<a href='http://example.com'>Example</a>\n"
    assert result == render "%a{href: 'http://example.com'} Example" |> eval([])
    assert result == render(~s(%a{href: 'http://example.com'}= "Example")) |> eval([conn: []])
  end

  test :render_with_params do
    assert "<a href='<%= url %>'><%= title %></a>\n" ==
      render haml_with_args()
  end

  test :render_with_args do
    assert "<a href='http://google.com'>Google</a>\n" ==
      render haml_with_args(), [ url: "http://google.com", title: "Google" ]
  end

  test :render_with_unin_args do
    assert "<a href='http://google.com'>Google</a>\n" ==
      render haml_with_unin_args(), [ url: "http://google.com", title: "Google" ]
  end

  test :render_with_unin_args_content_only do
    assert "<a href='http://google.com'>title</a>\n" ==
      render haml_with_unin_args_content_only(), [ url: "http://google.com" ]
  end

  test :render_with_unin_parens do
    assert "<a href='http://google.com'>Google</a>\n" ==
      render haml_with_unin_parens(), [ url: "http://google.com", title: "Google" ]
  end

  test :local_variable do
    expected = """
      <% var = "test" %>
      <p><%= var %></p>
      """

    haml = """
      - var = "test"
      %p= var
      """

    assert_equivalent_html(expected, render(haml))
  end

  test :case_evaluation do
    expected = """
      <%= case @var do %>
      <% nil -> %>
      <p>Found nil value</p>
      <% other -> %>
      <p>
      Found other:  <%= other %>
      </p>

      <% end %>
      """

    haml = """
      - case @var do
        -  nil ->
          %p Found nil value
        - other ->
          %p Found other:
            = other
      """

    assert_equivalent_html(expected, render(haml))
  end

  test :else_result do
    haml = """
      - if false do
        %p true
      - else
        %p false
      """

    assert_equivalent_html("<p>false</p>", EEx.eval_string(render(haml), []))
  end

  test :block_evaluation do
    expected = """
    <%= func do %>  text<% end %>
    """

    haml = """
    = func do
      text
    """

    assert_equivalent_html(expected, render(haml))
  end
end
