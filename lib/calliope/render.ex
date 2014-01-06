defmodule Calliope.Render do

  @line_matcher %r{(([ \t]+)?(.*?))(?:\Z|\r\n|\r|\n)}
  @id %r/#([a-z\d\w-]+)/i
  @class %r{}
  @div %r/^(%div|\.|\#)/
  @tabs %r/\t/
  @content %r/[^\t*]\s(.*$)/

  @self_closing ["br", "meta"]

  def render(haml), do: parse(haml)

  def parse(haml) do
    clean_haml(haml) |>
     haml_to_list    |>
     tokenize        |>
     process         |>
     Enum.join("")
  end

  def clean_haml(haml) do
    # remove unnescessary trailing whitespace
    String.strip(haml)
  end

  def haml_to_list(haml) do
    # convert the haml into a list
    Regex.scan(@line_matcher, haml) |> Enum.drop(-1)
  end

  def tokenize([]), do: []
  def tokenize([[full, tag, tabs, _]|t]) do
    # iterate over the list to build nodes
    # get the tag
    tab_count = (String.split(tabs, @tabs) |> Enum.count) - 1
    tag = cond do
      Regex.match?(@div, String.strip(full, ?\t)) -> "div"
      true -> ""
    end
    self_closing = Enum.member?(@self_closing, tag)
    content = match(@content, full)

    tokenized_list = [new_node(full, tag, tab_count, content, self_closing)] ++ tokenize(t)
    tokenized_list
  end

  def match(reg, text) do
    IO.puts inspect Regex.run(reg, text)
    [_, m] = Regex.run(reg, text)
    m
  end

  def process([]), do: []
  def process([[full: full, tag: tag, indent: _, content: content, self_closing: _]|t]) when tag != "" do
    # process each node to list of html tags
    ["<#{tag}>#{content}"] ++ process(t) ++ ["</#{tag}>"]
  end
  def process([h|t]) do
    nested_content(h) ++ process(t)
  end

  def nested_content([full: _, tag: tag, indent: indent, content: content, self_closing: _]) when tag == "" do
    [tabs(indent), content] |> wrap_newline
  end

  def wrap_newline(contents), do: ["\n", contents, "\n"]

  def tabs(0), do: []
  def tabs(count) do
    (["\t"] ++ tabs(count - 1)) |> Enum.join
  end

  def new_node(full, tag, indent, content, self_closing) do
    [ full: full, tag: tag, indent: indent, content: content, self_closing: self_closing ]
  end
end
