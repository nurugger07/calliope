defmodule CalliopeParserTest do
  use ExUnit.Case

  import Calliope.Parser

  @tokens [
      ["%section", ".container"],
      ["\t", "%h1", " Calliope"],
      ["\t", "%h2", " An Elixir Haml Parser"],
      ["\t", "#main", ".content"],
      ["\t\t", " Welcome to Calliope"],
      ["%section", ".container"],
    ]

  @parsed_tokens [
      [ tag: "section", classes: ["container"] ],
      [ indent: 1, tag: "h1", content: "Calliope" ],
      [ indent: 1, tag: "h2", content: "An Elixir Haml Parser" ],
      [ indent: 1, id: "main", classes: ["content"] ],
      [ indent: 2, content: "Welcome to Calliope" ],
      [ tag: "section", classes: ["container"] ]
    ]

  @nested_tree [
      [ tag: "section", classes: ["container"], children: [
          [ indent: 1, tag: "h1", content: "Calliope" ],
          [ indent: 1, tag: "h2",content: "An Elixir Haml Parser"],
          [ indent: 1, id: "main", classes: ["content"], children: [
              [ indent: 2, content: "Welcome to Calliope" ]
            ]
          ],
        ],
      ],
      [ tag: "section", classes: ["container"] ]
    ]

  @children Keyword.fetch!(Enum.first(@nested_tree), :children)

  test :parse do
    result = parse(@tokens)

    # Count root level
    assert Enum.count(result) == 2
    # Count children
    assert (Enum.count (Enum.first(result))) == 3
  end

  test :parse_line do
    assert parsed_tokens(0) == parsed_line_tokens(tokens(0))
    assert parsed_tokens(1) == parsed_line_tokens(tokens(1))
    assert parsed_tokens(2) == parsed_line_tokens(tokens(2))
    assert parsed_tokens(3) == parsed_line_tokens(tokens(3))
    assert parsed_tokens(4) == parsed_line_tokens(tokens(4))
    assert parsed_tokens(5) == parsed_line_tokens(tokens(5))
  end

  test :build_tree do
    assert @nested_tree == build_tree @parsed_tokens
  end

  test :pop_children do
    assert { [[indent: 0, tag: "bottom"], [indent: 1, tag: "bottom_child"]], [[ indent: 1, tag: "top_child"]] } == pop_children([indent: 0, tag: "top"], [[ indent: 1, tag: "top_child"], [indent: 0, tag: "bottom"], [indent: 1, tag: "bottom_child"]])
  end

  test :pop_children_with_unindented_parent do
    assert { [[indent: 0]], [[indent: 1]]} == pop_children([],[[indent: 1], [indent: 0]])
  end

  defp tokens(n), do: line(@tokens, n)

  defp parsed_tokens(n), do: Enum.sort line(@parsed_tokens, n)

  defp parsed_line_tokens(tokens), do: Enum.sort parse_line(tokens)

  defp line(list, n), do: Enum.fetch!(list, n)

end
