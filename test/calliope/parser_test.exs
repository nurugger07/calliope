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
      [ tag: "h1", indent: 1, content: "Calliope" ],
      [ tag: "h2", indent: 1, content: "An Elixir Haml Parser" ],
      [ id: "main", indent: 1, classes: ["content"] ],
      [ indent: 2, content: "Welcome to Calliope" ]
    ]

  test :parse_line do
    assert parsed_tokens(0) == parsed_line_tokens(tokens(0))
    assert parsed_tokens(1) == parsed_line_tokens(tokens(1))
    assert parsed_tokens(2) == parsed_line_tokens(tokens(2))
    assert parsed_tokens(3) == parsed_line_tokens(tokens(3))
    assert parsed_tokens(4) == parsed_line_tokens(tokens(4))
  end

  defp tokens(n), do: line(@tokens, n)

  defp parsed_tokens(n), do: Enum.sort line(@parsed_tokens, n)

  defp parsed_line_tokens(tokens), do: Enum.sort parse_line(tokens)

  defp line(list, n), do: Enum.fetch!(list, n)

end
