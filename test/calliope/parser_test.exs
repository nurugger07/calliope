defmodule CalliopeParserTest do
  use ExUnit.Case

  import Calliope.Parser

  @tokens [
      ["!!! 5"],
      ["%section", ".container", ".blue"],
      ["\t", "%h1", "Calliope"],
      ["\t", "/", "%h1", "An important inline comment"],
      ["\t", "/[if IE]"],
      ["\t\t", "%h2", "An Elixir Haml Parser"],
      ["\t", "#main", ".content"],
      ["\t\t", " Welcome to Calliope"],
      ["%section", ".container", "(data-a: 'calliope', data-b: 'awesome')"],
      ["\t", "%img", ".one", "{id: 'main_image', class: 'two three', src: '#'}"],
    ]

  @parsed_tokens [
      [ doctype: "!!! 5" ],
      [ tag: "section", classes: ["container", "blue"] ],
      [ indent: 1, tag: "h1", content: "Calliope" ],
      [ indent: 1, comment: "!--", tag: "h1", content: "An important inline comment" ],
      [ indent: 1, comment: "!--[if IE]" ],
      [ indent: 2, tag: "h2", content: "An Elixir Haml Parser" ],
      [ indent: 1, id: "main", classes: ["content"] ],
      [ indent: 2, content: "Welcome to Calliope" ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'" ],
      [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='#'" ]
    ]

  @nested_tree [
      [ doctype: "!!! 5" ],
      [ tag: "section", classes: ["container", "blue"], children: [
          [ indent: 1, tag: "h1", content: "Calliope" ],
          [ indent: 1, comment: "!--", tag: "h1", content: "An important inline comment" ],
          [ indent: 1, comment: "!--[if IE]", children: [
              [ indent: 2, tag: "h2",content: "An Elixir Haml Parser"]
            ]
          ],
          [ indent: 1, id: "main", classes: ["content"], children: [
              [ indent: 2, content: "Welcome to Calliope" ]
            ]
          ],
        ],
      ],
      [ tag: "section", classes: ["container"], attributes: "data-a='calliope' data-b='awesome'",children: [
          [ indent: 1, tag: "img", id: "main_image", classes: ["one", "two", "three"], attributes: "src='#'"]
        ]
      ]
    ]

  test :parse_line do
    assert parsed_tokens(0) == parsed_line_tokens(tokens(0))
    assert parsed_tokens(1) == parsed_line_tokens(tokens(1))
    assert parsed_tokens(2) == parsed_line_tokens(tokens(2))
    assert parsed_tokens(3) == parsed_line_tokens(tokens(3))
    assert parsed_tokens(4) == parsed_line_tokens(tokens(4))
    assert parsed_tokens(5) == parsed_line_tokens(tokens(5))
    assert parsed_tokens(6) == parsed_line_tokens(tokens(6))
    assert parsed_tokens(7) == parsed_line_tokens(tokens(7))
  end

  test :build_tree do
    assert @nested_tree == build_tree @parsed_tokens
  end

  defp tokens(n), do: line(@tokens, n)

  defp parsed_tokens(n), do: Enum.sort line(@parsed_tokens, n)

  defp parsed_line_tokens(tokens), do: Enum.sort parse_line(tokens)

  defp line(list, n), do: Enum.fetch!(list, n)

end
