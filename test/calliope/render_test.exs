defmodule CalliopeRenderTest do
  use ExUnit.Case

  use Calliope.Render

  @haml ~s{!!! 5
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
      Welcome to Calliope}

  @html ~s{<!DOCTYPE html>
<section class="container blue" style="margin-top: 10px" data-value='<%= @value %>'>
  <article>
    <h1><%= title %></h1>
    <script type="text/javascript">
      var x = 5;
      var y = 10;
    </script>
    <!-- <h1>An important inline comment</h1> -->
    <!--[if IE]>       <h2>An Elixir Haml Parser</h2> <![endif]-->
    <label class="cl1 cl2" for="test">Label</label>
    <div id="main" class="content">
      Welcome to Calliope
    </div>
  </article>
</section>
}

  @haml_with_args "%a{href: '#\{url}'}= title"

  test :render do
    assert String.replace(@html, "\n", "") == String.replace(render(@haml), "\n", "")
    assert "<h1>This is <%= title %></h1>\n" == render "%h1 This is \#{title}"
    assert "<a ng-click='doSomething()'>Click Me</a>\n" == render "%a{ng-click: 'doSomething()'} Click Me"
    assert "<h1>{{user}}</h1>\n" == render "%h1 {{user}}"
  end

  test :eval do
    result = "<a href='http://example.com'>Example</a>\n"
    assert result == render "%a{href: 'http://example.com'} Example" |> eval []
    assert result == render(~s(%a{href: 'http://example.com'}= "Example")) |> eval [conn: []]
  end

  test :render_with_params do
    assert "<a href='<%= url %>'><%= title %></a>\n" ==
      render @haml_with_args
  end

  test :render_with_args do
    assert "<a href='http://google.com'>Google</a>\n" ==
      render @haml_with_args, [ url: "http://google.com", title: "Google" ]
  end

  test :local_variable do

    expected = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <% var = "test" %>
      <p><%= var %></p>}, "")

    haml = """
- var = "test"
%p= var
"""
    assert expected == Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, render(haml), "")
  end

  test :case_evaluation do
    haml = ~s{- case @var do
  -  nil -> 
    %p Found nil value
  - other ->
    %p Found other: 
      = other
}

    expected = ~s{<%= case @var do %>
<% nil -> %>
<p>Found nil value</p>
<% other -> %>
<p>Found other:
  <%= other %></p>
<% end %>
}
    assert String.replace(expected, "\n", "") == String.replace(render(haml), "\n", "")
  end

  test :else_result do
    haml = """
- if false do
  %p true
- else 
  %p false
"""
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(haml), []), "")
    assert actual == "<p>false</p>" 
  end
end
