defmodule CalliopeIntegerationTest do
  use ExUnit.Case

  use Calliope.Render

  @haml """
- if false do
  %p true
- else 
  %p false
"""
  test :else_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>false</p>" 
  end

  @haml """
- if true do
  %p true
- else 
  %p false
"""
  test :if_result_with_else do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end
 
  @haml """
- if true do
  %p true
"""
  test :if_true_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end
 
  @haml """
- if false do
  %p true
"""
  test :if_false_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == ""
  end

  @haml """
- unless false do
  %p true
"""
  test :uneless_false_result do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>true</p>" 
  end

  @haml ~S(- unless true do
  %p false
- else 
  %p true
)
  test :unless_result_with_else do
    actual = EEx.eval_string(render(@haml), [])
    assert actual == "\n<p>true</p>\n" 
  end
 
  @haml ~S(- answer = "42"
%p
  The answer is
  = " #{answer}"
)
  test :local_variable do
    actual = EEx.eval_string(render(@haml), [])
    assert actual == "<p>\n  The answer is\n   42\n</p>\n"
  end

  @haml ~S(
- for x <- [1,2] do
  %p= x
)
  test :for_evaluation do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>1</p><p>2</p>"
  end

  @haml ~S(
- case 1 + 1 do
  - 1 -> 
    %p Got one
  - 2 ->
    %p Got two
  - other -> 
    %p= "Got other #{other}"
)
  test :case_evaluation do
    actual = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, EEx.eval_string(render(@haml), []), "")
    assert actual == "<p>Got two</p>"
  end

  @haml ~S(
.simple_div
    %b Label:
    Content
Outside the div
)
  @expected ~S(<div class="simple_div">
  <b>Label:</b>
  Content
</div>
Outside the div
)
  test :preserves_newlines do
    assert EEx.eval_string(render(@haml), []) == @expected
  end


  @haml ~s{!!! 5
%section.container
  %h1
    = arg
  <!-- <h1>An important inline comment</h1> -->
  <!--[if IE]> <h2>An Elixir Haml Parser</h2> <![endif]-->
  #main.content
    Welcome to Calliope
    %br
%section.container
  %img(src='#')
}

  @expected ~s{<!DOCTYPE html>
<section class="container">
  <h1>
    <%= arg %>
  </h1>
  <!-- <h1>An important inline comment</h1> -->
  <!--[if IE]> <h2>An Elixir Haml Parser</h2> <![endif]-->
  <div id="main" class="content">
    Welcome to Calliope
    <br>
  </div>
</section>
<section class="container">
  <img src='#'>
</section>
}
  test :preserves_newlines_with_comments do
    assert render(@haml) == @expected
  end
end
