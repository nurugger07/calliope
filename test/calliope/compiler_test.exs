defmodule CalliopeCompilerTest do
  use ExUnit.Case

  import Calliope.Compiler

  @ast [
    [doctype: "!!! 5"],
    [tag: "section", classes: ["container"], children: [
        [indent: 1, tag: "h1", children: [
            [indent: 2, script: "arg"]
          ]
        ],
        [indent: 1, tag: "h1",  comment: "!--", content: "An important inline comment"],
        [content: "<!--[if IE]> <h2>An Elixir Haml Parser</h2> <![endif]-->",
            indent: 1, line_number: 6],
        [indent: 1, id: "main", classes: ["content"], children: [
            [indent: 2, content: "Welcome to Calliope"],
            [indent: 2, tag: "br"]
          ]
        ],
      ],
    ],
    [tag: "section", classes: ["container"], children: [
        [indent: 1, tag: "img", attributes: "src='#'"]
      ]
    ]
  ]

  @html ~s{<!DOCTYPE html>
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

  @smart [[smart_script: "for { id, content } <- posts do", children: [
              [indent: 1, tag: "div", children: [[indent: 2, script: "content"]]]
            ]]]

  @smart_haml_comments [
      [tag: "p", content: "foo", children: [
          [indent: 1, smart_script: "# This would", children: [
              [indent: 2, content: "Not be"],
              [indent: 2, content: "output"]
            ],
          ]
        ]
      ],
      [tag: "p", content: "bar"]
    ]

  test :precompile_content do
    assert "Hello <%= name %>" == precompile_content("Hello \#{name}")
  end

  test :compile_attributes do
    assert " id=\"foo\" class=\"bar baz\"" ==
      compile_attributes([id: "foo", classes: ["bar", "baz"]])
    assert " class=\"bar\"" == compile_attributes([classes: ["bar"]])
    assert " id=\"foo\"" == compile_attributes([id: "foo"])
  end

  test :compile_key do
    assert " class=\"content\"" == compile_key({:classes, ["content"]})
    assert " id=\"foo\"" == compile_key({:id, "foo"})
  end

  test :tag do
    refute tag([foo: "bar"])
    assert "div" == tag([tag: "div"])
    assert "div" == tag([id: "foo"])
    assert "div" == tag([classes: ["bar"]])
    assert "section" == tag([tag: "section"])
    assert "!!! 5" == tag([doctype: "!!! 5"])
    assert nil == tag([content: "Welcome to Calliope"])
  end

  test :open do
    assert "<div>" == open("", :div)
    assert "<section>" == open("", :section)
    assert "" == open("", nil)

    assert "<!DOCTYPE html>" == open("", "!!! 5")
    assert "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" == open("", "!!!")

    assert "<div id=\"foo\" class=\"bar\">" == open(" id=\"foo\" class=\"bar\"", :div)
  end

  test :close do
    assert "</div>" == close("div")
    assert "</section>" == close("section")
    assert "" == close(nil)

    assert "" == close("br")
    assert "" == close("link")
  end

  test :compile do
     assert ~s{<div id="test"></div>\n} == compile([[id: "test"]])
     assert ~s{<section id="test" class="content"></section>\n} == compile([[tag: "section", id: "test", classes: ["content"]]])

     children = [[classes: ["nested"]]]
     assert ~s{<div id="test">\n<div class="nested"></div>\n</div>\n} == compile([[id: "test", children: children]])

     assert ~s{content} <> "\n" == compile([[content: "content"]])

     assert @html == compile(@ast)
  end

  test :compile_with_multiline_script do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <h1>Calliope</h1>
      <%= for a <- b do %>
        <div><%= a %></div>
      <% end %>}, "")

    parsed_tokens = [
      [indent: 1, tag: "h1", content: "Calliope"],
      [indent: 1, smart_script: "for a <- b do", children: [
          [indent: 2, tag: "div", script: "a"]
        ]
      ]
    ]

    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")

    assert expected_results == compiled_results
  end

  test :compile_with_cond_evaluation do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <%= cond do %>
        <% (1 + 1 == 1) -> %>
          <p>No1</p>
        <% (2 * 2 != 4) -> %>
          <p>No2</p>
        <% true -> %>
          <p>Yes</p>
      <% end %>}, "")

    parsed_tokens = [
      [indent: 1, smart_script: "cond do", children: [
        [indent: 2, smart_script: "(1 + 1 == 1) ->", children: [[indent: 3, tag: "p", content: "No1"]]],
        [indent: 2, smart_script: "(2 * 2 != 4) ->", children: [[indent: 3, tag: "p", content: "No2"]]],
        [indent: 2, smart_script: "true ->", children: [[indent: 3, tag: "p", content: "Yes"]]]]]]

    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")

    assert expected_results == compiled_results
  end

  test :compile_with_if_evaluation do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <%= if test > 5 do %>
         <p>No1</p>
      <% end %>}, "")

    parsed_tokens = [
      [indent: 1, smart_script: "if test > 5 do", children: [[indent: 2, tag: "p", content: "No1"]]],
    ]
    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")

    assert expected_results == compiled_results
  end

  test :compile_with_if_else_evaluation do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <%= if test > 5 do %>
         <p>No1</p>
      <% else %>
         <p>No2</p>
      <% end %>}, "")

    parsed_tokens = [
      [indent: 1, smart_script: "if test > 5 do", children: [[indent: 2, tag: "p", content: "No1"]]],
      [indent: 1, smart_script: "else", children: [[indent: 2, tag: "p", content: "No2"]]]
    ]
    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")

    assert expected_results == compiled_results
  end

  test :compile_with_unless_evaluation do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <%= unless test > 5 do %>
         <p>No1</p>
      <% end %>}, "")

    parsed_tokens = [
      [indent: 1, smart_script: "unless test > 5 do", children: [[indent: 2, tag: "p", content: "No1"]]],
    ]
    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")

    assert expected_results == compiled_results
  end

  test :compile_with_unless_else_evaluation do
    expected_results = ~s{<%= unless test > 5 do %>
  <p>No1</p>
<% else %>
  <p>No2</p>
<% end %>}

    parsed_tokens = [
      [indent: 1, smart_script: "unless test > 5 do", children: [[indent: 2, tag: "p", content: "No1"]]],
      [indent: 1, smart_script: "else", children: [[indent: 2, tag: "p", content: "No2"]]]
    ]
    compiled_results = compile(parsed_tokens)
    assert expected_results == compiled_results
  end

  test :compile_local_variables do
    expected_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, ~s{
      <% test = "testing" %>
      <%= test %>}, "")

    parsed_tokens = [
      [smart_script: "test = \"testing\"", line_number: 1],
      [script: " test", line_number: 2]
    ]
    compiled_results = Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, compile(parsed_tokens), "")
    assert expected_results == compiled_results
  end

  test :preserves_indentation_and_new_lines do
    expected = "  <div>\n    <b>Test</b>\n  </div>\n"
    parsed_tokens = [
      [indent: 1, tag: "div", line_number: 1, children: [
          [indent: 2, tag: "b", content: "Test", line_number: 2]
        ]
      ]
    ]
    assert expected == compile(parsed_tokens)
  end

  test :preserves_indentation_and_new_lines_2 do
    expected = "<div class=\"simple_div\">\n  <b>Label:</b>\n  Content\n</div>\nOutside the div\n"
    parsed_tokens = [[line_number: 1, classes: ["simple_div"], children: [
      [content: "Label:", tag: "b", indent: 1, line_number: 2],
      [content: "Content", indent: 1, line_number: 3]]],
      [content: "Outside the div", line_number: 4]]
    assert compile(parsed_tokens) == expected
  end

  @expected ~s[<%= form_for @changeset, @action, fn f -> %>
<div class=\"test\"></div>

<% end %>]

  test :render_anonymous_functions do
    parsed_tokens = [
      [smart_script: "form_for @changeset, @action, fn f ->", line_number: 1,
        children: [[line_number: 2, indent: 1, classes: ["test"]]]]
    ]
    assert compile(parsed_tokens) == @expected
  end

  @expected ~s[<%= form_for @changeset, @action, fn(f) -> %>
<div class=\"test\"></div>

<% end %>]

  test :render_anonymous_function_parens do
    parsed_tokens = [
      [smart_script: "form_for @changeset, @action, fn(f) ->", line_number: 1,
        children: [[line_number: 2, indent: 1, classes: ["test"]]]]
    ]
    assert compile(parsed_tokens) == @expected
  end

  @expected ~s[<%= form_for(@changeset, @action, fn(f) -> %>
<div class=\"test\"></div>

<% end) %>]

  test :render_anonymous_functions_parens_2 do
    parsed_tokens = [
      [smart_script: "form_for(@changeset, @action, fn(f) ->", line_number: 1,
        children: [[line_number: 2, indent: 1, classes: ["test"]]]]
    ]
    assert compile(parsed_tokens) == @expected
  end
end
