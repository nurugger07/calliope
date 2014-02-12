defmodule CalliopeTokenizerTest do
  use ExUnit.Case

  import Calliope.Tokenizer

  @haml %s{
!!! 5
%section.container
  %h1 Calliope
  / %h1 An important inline comment
  /[if IE]
    %h2 An Elixir Haml Parser
  .content
    = arg
    Welcome to Calliope}

  test :tokenize_inline_haml do
    inline = "%div Hello Calliope"
    assert [["%div","Hello Calliope"]] == tokenize(inline)
    assert [["%h1", "This is \#{title}"]] == tokenize("%h1 This is \#{title}")
  end

  test :tokenize_multiline_haml do
    assert [
      ["!!! 5"],
      ["%section", ".container"],
      ["\t", "%h1", "Calliope"],
      ["\t", "/ ", "%h1", "An important inline comment"],
      ["\t", "/[if IE]"],
      ["\t\t", "%h2", "An Elixir Haml Parser"],
      ["\t", ".content"],
      ["\t\t", "= arg"],
      ["\t\t", "Welcome to Calliope"]
    ] == tokenize(@haml)
  end

  test :tokenize_line do
    assert [["%section", ".container", ".blue", "{src='#', data='cool'}", "Calliope"]] ==
      tokenize("\n%section.container.blue{src='#', data='cool'} Calliope")
    assert [["%section", ".container", "(src='#', data='cool')", "Calliope"]] ==
      tokenize("\n%section.container(src='#', data='cool') Calliope")
    assert [["\t", "%a", "{href: \"#\"}", "Learning about \#{title}"]] ==
      tokenize("\t%a{href: \"#\"} Learning about \#{title}")
  end

  test :tokenize_identation do
    assert [
        ["%section"],
        ["\t", "%h1", "Calliope"],
        ["\t", "%h2", "Subtitle"],
        ["\t\t", "%section"]
      ] == tokenize_identation [
        ["%section"],
        ["  ", "%h1", "Calliope"],
        ["  ", "%h2", "Subtitle"],
        ["    ", "%section"]
      ], 2
  end

  test :compute_tabs do
    assert 0 == compute_tabs [["aa"]]
    assert 2 == compute_tabs [["aa"], ["  ", "aa"]]
    assert 4 == compute_tabs [["aa"], ["    ", "aa"]]
    assert 2 == compute_tabs [["aa"], ["  ", "aa"], ["    ", "aa"]]
  end

end
