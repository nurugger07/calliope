defmodule Calliope.Render do

  @line_matcher %r{(([ \t]+)?(.*?))(?:\Z|\r\n|\r|\n)}
  @id %r{#([a-z\d\w-]+)}
  @class %r{}
  @div %r/^(%div|\.|\#)/
  @tabs %r/\t/

  @self_closing ["br", "meta"]

  defrecordp :node, full: "",  tag: "", id: "", class: [], attributes: [], indent: 0, self_closing: true

  def render(haml), do: parse(haml)

  def parse(haml) do
    clean_haml(haml) |>
     haml_to_list    |>
     tokenize        |>
     process         |>
     Enum.join("\n")
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
    tag = cond do
      Regex.match?(@div, tag) -> "div"
    end
    # count whitespace
    # id           = get_id(full)
    tab_count    = (String.split(tabs, @tabs) |> Enum.count) - 1
    # classes      = [read_classes(full)]
    # attributes   = [read_attributes(full)]
    self_closing = Enum.member?(@self_closing, tag)

    [new_node(full, tag, tab_count, self_closing)] ++ tokenize(t)
  end

  def process([]), do: []
  def process([_h|t]) do
    # process each node to list of html tags
    process(t)
  end

  def new_node(full, tag, indent, self_closing) do
    node(full: full, tag: tag, indent: indent, self_closing: self_closing)
  end

end
