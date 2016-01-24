defmodule CalliopeParserTest do
  use ExUnit.Case

  import Calliope.Parser

  @tokens [
      [1, "!!! 5"],
      [2, "%section", ".container", ".blue"],
      [3, "\t", "%h1", "Calliope"],
      [4, "\t", "/", "%h1", "An important inline comment"],
      [5, "\t", "/[if IE]"],
      [6, "\t\t", "%h2", "An Elixir Haml Parser"],
      [7, "\t", "#main", ".content"],
      [8, "\t\t", "- for { arg } <- args do"],
      [9, "\t\t\t", "= arg"],
      [10, "\t\t", " Welcome to \#{title}"],
      [11, "%section", ".container", "(data-a: 'calliope', data-b: 'awesome')"],
      [12, "\t", "%img", ".one", "{id: 'main_image', class: 'two three', src: url}"],
      [13, "\t", ":javascript"]
    ]

  @parsed_tokens [
      [ doctype: "!!! 5", line_number: 1],
      [ tag: "section", classes: ["container", "blue"] , line_number: 2],
      [ indent: 1, tag: "h1", content: "Calliope", line_number: 3 ],
      [ indent: 1, comment: "!--", tag: "h1", content: "An important inline comment", line_number: 4 ],
      [ indent: 1, comment: "!--[if IE]", line_number: 5 ],
      [ indent: 2, tag: "h2", content: "An Elixir Haml Parser", line_number: 6 ],
      [ indent: 1, id: "main", classes: ["content"], line_number: 7 ],
      [ indent: 2, smart_script: "for { arg } <- args do", line_number: 8 ],
      [ indent: 3, script: " arg", line_number: 9 ],
      [ indent: 2, content: "Welcome to \#{title}", line_number: 10 ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'", line_number: 11 ],
      [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='\#{url}'", line_number: 12 ],
      [ indent: 1, tag: "script", attributes: "type=\"text/javascript\"", line_number: 13 ]
    ]

  @nested_tree [
      [ doctype: "!!! 5", line_number: 1],
      [ tag: "section", classes: ["container", "blue"], line_number: 2, children: [
          [ indent: 1, tag: "h1", content: "Calliope", line_number: 3 ],
          [ indent: 1, comment: "!--", tag: "h1", content: "An important inline comment", line_number: 4 ],
          [ indent: 1, comment: "!--[if IE]", line_number: 5, children: [
              [ indent: 2, tag: "h2",content: "An Elixir Haml Parser", line_number: 6]
            ]
          ],
          [ indent: 1, id: "main", classes: ["content"], line_number: 7, children: [
              [ indent: 2, smart_script: "for { arg } <- args do", line_number: 8, children: [
                  [ indent: 3, script: " arg", line_number: 9 ]
                ]
              ],
              [ indent: 2, content: "Welcome to \#{title}", line_number: 10 ]
            ]
          ],
        ],
      ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'", line_number: 11, children: [
          [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='\#{url}'", line_number: 12 ],
          [ indent: 1, tag: "script", attributes: "type=\"text/javascript\"", line_number: 13 ]
        ]
      ]
    ]

  @tokens_with_haml_comment [
      [1, "%p", "foo"],
      [2, "\t", "-# This would"],
      [3, "\t\t", "Not be"],
      [4, "\t\t", "output"],
      [5, "%p", "bar"]
    ]

  @parsed_with_haml_comment [
      [ content: "foo", tag: "p", line_number: 1,children: [
          [ smart_script: "# This would", indent: 1, line_number: 2, children: [
              [ content: "Not be", indent: 2, line_number: 3],
              [ content: "output", indent: 2, line_number: 4]
            ],
          ]
        ]
      ],
      [ content: "bar", tag: "p", line_number: 5 ]
    ]

  test :parse do
    assert @parsed_with_haml_comment == parse @tokens_with_haml_comment
  end

  test :parse_with_special_cases do
    handle_bars = [[1, "%h1", "{{user}}"]]
    parsed_handle_bars = [[ content: "{{user}}", tag: "h1", line_number: 1 ]]
    assert parsed_handle_bars == parse handle_bars
  end

  test :parse_with_no_space_after_tag do
    assert [[attributes: "foo", tag: "h1", line_number: 1]] == parse([[1, "%h1", "(foo)"]])
  end

  test :parse_with_space_after_tag do
    assert [[content: "(foo)", tag: "h1", line_number: 1]] == parse([[1, "%h1 ", " (foo)"]])
  end

  test :parse_line do
    each_token_with_index fn({ token, index }) ->
      assert parsed_tokens(index) == parsed_line_tokens(token)
    end
  end

  test :build_tree do
    assert @nested_tree == build_tree @parsed_tokens
  end

  test :build_attributes do
    assert "class='#\{@class_name}'" == build_attributes("class: @class_name }")
    assert "for='name'" == build_attributes("for:  'name' }")
    assert "class='#\{@class_name}'" == build_attributes("class=@class_name }")
    assert "style='margin-top: 5px'" == build_attributes("style: 'margin-top: 5px' }")
    assert "style=\"margin-top: 5px\"" == build_attributes("style: \"margin-top: 5px\" }")
    assert "href='http://google.com'" == build_attributes("href: 'http://google.com' }")
    assert "src='#\{url}'" == build_attributes("src: url }")
    assert "some-long-value='#\{@value}'" == build_attributes("\"some-long-value\" => @value }")
    assert "href=\"#\{fun(one, two)}\" style='abc: 1'" == build_attributes("href: \"\#{fun(one, two)}\", style: 'abc: 1'}")
  end

  test :haml_exceptions do
    msg = "tag id is assigned multiple times on line number 1"
    assert_raise CalliopeException, msg, fn() ->
      parse([[1, "#main", "#another_id"]])
    end

    msg = "Indentation was too deep on line number: 3"
    assert_raise CalliopeException, msg, fn() ->
      parse([[1, "#main"],
             [2, "\t", "%h1", "Calliope"],
             [3, "\t\t\t", "%h2", "Indent Too Deep" ]])
    end

    msg = "Unknown filter on line number: 1"
    assert_raise CalliopeException, msg, fn() ->
      parse([ [1, ":unknown"] ])
    end
  end

  test :function_in_attributes do
    tokens = [[1, "%a", "{href: '\#{page_path(conn, 1)}'}", " Link"]]
    expected = [
      [content: "Link", attributes: "href='\#{page_path(conn, 1)}'", tag: "a", line_number: 1]
    ]
    assert parse(tokens) == expected
  end

  test :dashed_attribute_names do
    tokens = [[1, "%li", "(ng-class=\"followees_tab\")"]]
    expected = %{attributes: "ng-class=\"followees_tab\"", line_number: 1, tag: "li"}
    [result] = parse(tokens)

    assert Enum.into(result, %{}) == expected
  end

  test :hash_rocket_attributes do
    tokens = [[1, "%p", ".alert", ".alert-info", "{:role => \"alert\"}", "= get_flash(@conn, :info)"]]
    expected = %{attributes: "role='alert'", script: " get_flash(@conn, :info)", tag: "p", line_number: 1, classes: ["alert", "alert-info"]}
    [result] = parse(tokens)

    assert Enum.into(result, %{}) == expected
  end

  test :hash_rocket_script_attribute_exception do
    # %script{:src => static_path(@conn, "/js/app.js")}
    tokens = [[1, "%script", "{:src => static_path(@conn, \"/js/app.js\")}"]]
    assert_raise CalliopeException, ~r/Invalid attribute/, fn -> 
      parse(tokens)
    end
  end 

  test :hash_script_exception do
    assert_raise CalliopeException, ~r/Invalid attribute/, fn -> 
      parse([[1, ".cls", "#id", "{attr: myfunc(1,2), attr2: \"test\"}", "= one"]])
    end
  end
  defp parsed_tokens(n), do: Enum.sort line(@parsed_tokens, n)

  defp parsed_line_tokens(tokens), do: Enum.sort parse_line(tokens)

  defp line(list, n), do: Enum.fetch!(list, n)

  defp each_token_with_index(function) do
    Enum.each Enum.with_index(@tokens), function
  end
end
