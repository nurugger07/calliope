defmodule CalliopeTokenizerTest do
  use ExUnit.Case

  import Calliope.Tokenizer

  @haml "%section.container\n\t%h1 Calliope\n\t%h2 An Elixir Haml Parser\n\t.content\n\t\tWelcome to Calliope"

  test :tokenize_inline_haml do
    inline = "%div Hello Calliope"
    assert [["%div","Hello Calliope"]] == tokenize(inline)
  end

  test :tokenize_multiline_haml do
    assert [
      ["%section", ".container"],
      ["\t", "%h1", "Calliope"],
      ["\t", "%h2", "An Elixir Haml Parser"],
      ["\t", ".content"],
      ["\t\t", "Welcome to Calliope"]
    ] == tokenize(@haml)
  end

end
