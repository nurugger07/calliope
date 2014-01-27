defmodule CalliopeCompilerTest do
  use ExUnit.Case

  import Calliope.Compiler

  @ast [
    [ tag: "section", classes: ["container"], children: [
        [ indent: 1, tag: "h1", content: "Calliope" ],
        [ indent: 1, tag: "h2", content: "An Elixir Haml Parser"],
        [ indent: 1, id: "main", classes: ["content"], children: [
            [ indent: 2, content: "Welcome to Calliope" ]
          ]
        ],
      ],
    ],
    [ tag: "section", classes: ["container"] ]
  ]

  @html Regex.replace(%r/(^\s*)|(\s+$)|(\n)/m, %s{
    <section class="container">
      <h1>Calliope</h1>
      <h2>An Elixir Haml Parser</h2>
      <div id="main" class="content">
        Welcome to Calliope
      </div>
    </section>
    <section class="container"></section>
  }, "")

  test :indents do
    assert ["\t\t\t"] == indents(3)
    assert ["\t\t"] == indents(2)
    assert ["\t"] == indents(1)
    assert [""] == indents(0)
  end

  test :compile_attributes do
    assert " id=\"foo\" class=\"bar\"" ==  compile_attributes([ id: "foo", classes: ["bar"] ])
    assert " class=\"bar\"" ==  compile_attributes([ classes: ["bar"] ])
    assert " id=\"foo\"" ==  compile_attributes([ id: "foo"])
  end

  test :compile_key do
    assert " class=\"content\"" == compile_key({ :classes, ["content"] })
    assert " id=\"foo\"" == compile_key({ :id, "foo" })
  end

  test :tag do
    refute tag([ foo: "bar" ])
    assert "div" == tag([tag: "div"])
    assert "div" == tag([id: "foo"])
    assert "div" == tag([classes: ["bar"]])
    assert "section" == tag([tag: "section"])
    assert nil == tag([content: "Welcome to Calliope"])
  end

  test :open do
    assert "<div>"     == open("", :div)
    assert "<section>" == open("", :section)
    assert "" == open("", nil)

    assert "<div id=\"foo\" class=\"bar\">" == open(" id=\"foo\" class=\"bar\"", :div)
  end

  test :close do
    assert "</div>" == close("div")
    assert "\t\t</div>" == close("div", ["\t\t"])
    assert "</section>" == close("section")
    assert "" == close(nil)
  end

  test :compile do
     assert %s{<div id="test"></div>} == compile([[id: "test"]])
     assert %s{<section id="test" class="content"></section>} == compile([[tag: "section", id: "test", classes: ["content"]]])

     children = [[classes: ["nested"]]]
     assert %s{<div id="test"><div class="nested"></div></div>} == compile([[id: "test", children: children]])

     assert %s{content} == compile([[content: "content"]])

     assert @html == compile(@ast)
  end
end
