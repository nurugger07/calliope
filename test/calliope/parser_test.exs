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
      [8, "\t\t", "- lc { arg } inlist args do"],
      [9, "\t\t\t", "= arg"],
      [10, "\t\t", " Welcome to \#{title}"],
      [11, "%section", ".container", "(data-a: 'calliope', data-b: 'awesome')"],
      [12, "\t", "%img", ".one", "{id: 'main_image', class: 'two three', src: url}"],
    ]

  @parsed_tokens [
      [ doctype: "!!! 5", line_number: 1],
      [ tag: "section", classes: ["container", "blue"] , line_number: 2],
      [ indent: 1, tag: "h1", content: "Calliope", line_number: 3 ],
      [ indent: 1, comment: "!--", tag: "h1", content: "An important inline comment", line_number: 4 ],
      [ indent: 1, comment: "!--[if IE]", line_number: 5 ],
      [ indent: 2, tag: "h2", content: "An Elixir Haml Parser", line_number: 6 ],
      [ indent: 1, id: "main", classes: ["content"], line_number: 7 ],
      [ indent: 2, smart_script: "lc { arg } inlist args do", line_number: 8 ],
      [ indent: 3, script: " arg", line_number: 9 ],
      [ indent: 2, content: "Welcome to \#{title}", line_number: 10 ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'", line_number: 11 ],
      [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='\#{url}'", line_number: 12 ]
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
              [ indent: 2, smart_script: "lc { arg } inlist args do", line_number: 8, children: [
                  [ indent: 3, script: " arg", line_number: 9 ]
                ]
              ],
              [ indent: 2, content: "Welcome to \#{title}", line_number: 10 ]
            ]
          ],
        ],
      ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'", line_number: 11, children: [
          [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='\#{url}'", line_number: 12]
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
      [ line_number: 1, tag: "p", content: "foo", children: [
          [ line_number: 2, indent: 1, smart_script: "# This would", children: [
              [ line_number: 3, indent: 2, content: "Not be"],
              [ line_number: 4, indent: 2, content: "output"]
            ],
          ]
        ]
      ],
      [ line_number: 5, tag: "p", content: "bar"]
    ]

  test :parse do
    assert @parsed_with_haml_comment == parse @tokens_with_haml_comment
  end

  test :parse_with_special_cases do
    handle_bars = [[1, "%h1", "{{user}}"]]
    parsed_handle_bars = [[ line_number: 1, tag: "h1", content: "{{user}}"]]
    assert parsed_handle_bars == parse handle_bars
  end

  test :parse_line do
    assert parsed_tokens(0) == parsed_line_tokens(tokens(0))
    assert parsed_tokens(1) == parsed_line_tokens(tokens(1))
    assert parsed_tokens(2) == parsed_line_tokens(tokens(2))
    assert parsed_tokens(3) == parsed_line_tokens(tokens(3))
    assert parsed_tokens(4) == parsed_line_tokens(tokens(4))
    assert parsed_tokens(5) == parsed_line_tokens(tokens(5))
    assert parsed_tokens(6) == parsed_line_tokens(tokens(6))
    assert parsed_tokens(7) == parsed_line_tokens(tokens(7))
    assert parsed_tokens(8) == parsed_line_tokens(tokens(8))
    assert parsed_tokens(9) == parsed_line_tokens(tokens(9))
    assert parsed_tokens(10) == parsed_line_tokens(tokens(10))
  end

  test :build_tree do
    assert @nested_tree == build_tree @parsed_tokens
  end

  test :build_attributes do
    assert "href='http://google.com'" == build_attributes("href: 'http://google.com' }")
    assert "src='\#{url}'" == build_attributes("src: url }")
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
  end

  defp tokens(n), do: line(@tokens, n)

  defp parsed_tokens(n), do: Enum.sort line(@parsed_tokens, n)

  defp parsed_line_tokens(tokens), do: Enum.sort parse_line(tokens)

  defp line(list, n), do: Enum.fetch!(list, n)

end
