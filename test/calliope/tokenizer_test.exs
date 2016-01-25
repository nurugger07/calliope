defmodule CalliopeTokenizerTest do
  use ExUnit.Case

  import Calliope.Tokenizer

  @haml ~s{
!!! 5
%section.container
  %h1 Calliope
  / %h1 An important inline comment
  /[if IE]
    %h2 An Elixir Haml Parser
  .content
    = arg
    Welcome to Calliope}

  @haml_with_collection  """
- for { content } <- posts do
  %div
    = content
"""

  @haml_with_haml_comments """
%p foo
  -# This would
    Not be
    output
%p bar
"""

  test :tokenize_inline_haml do
    inline = "%div Hello Calliope"
    assert [[1, "%div"," Hello Calliope"]] == tokenize(inline)
    assert [[1, "%h1", " This is \#{title}"]] == tokenize("%h1 This is \#{title}")

    inline = "%a{ng-click: 'doSomething()'}Click Me"
    assert [[1, "%a", "{ng-click: 'doSomething()'}", "Click Me"]] == tokenize inline

    inline = "%h1 {{user}}"
    assert [[1, "%h1", " {{user}}"]] == tokenize inline
  end

  test :tokenize_multiline_haml do
    assert [
      [1, "!!! 5"],
      [2, "%section", ".container"],
      [3, "\t", "%h1", " Calliope"],
      [4, "\t", "/ ", "%h1", " An important inline comment"],
      [5, "\t", "/[if IE]"],
      [6, "\t\t", "%h2", " An Elixir Haml Parser"],
      [7, "\t", ".content"],
      [8, "\t\t", "= arg"],
      [9, "\t\t", "Welcome to Calliope"]
    ] == tokenize(@haml)

    assert [
      [1, "- for { content } <- posts do"],
      [2, "\t", "%div"],
      [3, "\t\t", "= content"]
      ] == tokenize(@haml_with_collection)

    assert [
      [1, "%p", " foo"],
      [2, "\t", "-# This would"],
      [3, "\t\t", "Not be"],
      [4, "\t\t", "output"],
      [5, "%p", " bar"]
      ] == tokenize(@haml_with_haml_comments)
  end

  test :tokenize_line do
    assert [[1, "%section", ".container", ".blue", "{src:'#', data:'cool'}", " Calliope"]] ==
      tokenize("\n%section.container.blue{src:'#', data:'cool'} Calliope")
    assert [[1, "%section", ".container", "(src='#' data='cool')", " Calliope"]] ==
      tokenize("\n%section.container(src='#' data='cool') Calliope")
    assert [[1, "\t", "%a", "{href: \"#\"}", " Learning about \#{title}"]] ==
      tokenize("\t%a{href: \"#\"} Learning about \#{title}")

    # allowing spaces after the attribute values before closing curly brace
    assert [[1, "%label", ".cl1", "{ for:  'test', class:  ' cl2' }", " Label" ]] ==
      tokenize("%label.cl1{ for:  'test', class:  ' cl2' } Label")

    assert [[1, "%label", "{ for: \"\#{@id}\", class: \"\#{@class}\" }", " Label" ]] ==
      tokenize("%label{ for: \"\#{@id}\", class: \"\#{@class}\" } Label")
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

  test :index do
    assert [
        [1, "%section"],
        [2, "\t", "%h1", "Calliope"],
        [3, "\t", "%h2", "Subtitle"],
        [4, "\t\t", "%section"]
      ] == index [
        ["%section"],
        ["\t", "%h1", "Calliope"],
        ["\t", "%h2", "Subtitle"],
        ["\t\t", "%section"]
      ]
  end

  test :compute_tabs do
    assert 0 == compute_tabs [["aa"]]
    assert 2 == compute_tabs [["aa"], ["  ", "aa"]]
    assert 4 == compute_tabs [["aa"], ["    ", "aa"]]
    assert 2 == compute_tabs [["aa"], ["  ", "aa"], ["    ", "aa"]]
  end

  test :parse_with_space do
    assert [[1, "%h1", " (foo)"]] == tokenize("%h1 (foo)")
    assert [[1, "%h1", "(foo)"]] == tokenize("%h1(foo)")
  end

  test :parse_with_content do
    assert [[1, "%h1", " foo"]] == tokenize("%h1 foo")
  end

  test :hash_rocket do
    result = tokenize ~S[%p.alert.alert-info{:style => "one"}= get_flash(@conn, :info)]
    expected = [[1, "%p", ".alert", ".alert-info", "{:style => \"one\"}", "= get_flash(@conn, :info)"]]
    assert expected == result
  end

end
