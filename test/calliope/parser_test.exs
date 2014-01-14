defmodule CalliopeParserTest do
  use ExUnit.Case

  import Calliope.Parser

  @tokens [
      ["%section", ".container"],
      ["\t", "%h1", " Calliope"],
      ["\t", "%h2", " An Elixir Haml Parser"],
      ["\t", "#main", ".content"],
      ["\t\t", " Welcome to Calliope"]
    ]

  @parsed_tokens [
      [ tag: "section", classes: ["container"] ],
      [ indent: 1, tag: "h1", content: "Calliope" ],
      [ indent: 1, tag: "h2", content: "An Elixir Haml Parser" ],
      [ id: "main", indent: 1, classes: ["content"] ],
      [ indent: 2, content: "Welcome to Calliope" ]
    ]

  test :parse_line do
    assert parsed_tokens(0)  == parse_line tokens(0)
    assert parsed_tokens(1)  == parse_line(tokens(1))
    assert parsed_tokens(2)  == parse_line(tokens(2))
    assert parsed_tokens(3)  == parse_line(tokens(3))
    assert parsed_tokens(4)  == parse_line(tokens(4))
  end

  test :merge_into_classes do
    list = [ classes: "class1" ]
    assert [ classes: ["class1", "class2"] ] == merge_into(:classes, list, "class2")
  end

  defp tokens(n), do: line(@tokens, n)

  defp parsed_tokens(n), do: line(@parsed_tokens, n)

  defp line(list, n), do: Enum.fetch!(list, n)
end
