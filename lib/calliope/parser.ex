defmodule Calliope.Parser do

  @tag      "%"
  @id       "#"
  @class    "."
  @content  " "
  @tab      "\t"

  def parse([]), do: []
  def parse([_|t]) do
    parse(t)
  end

  def parse_line([], acc), do: acc
  def parse_line([h|t], acc//[]) do
    [sym, val] = [head(h), tail(h)]
    acc = case sym do
      @tag      -> acc ++ [ tag: val ]
      @id       -> acc ++ [ id: val ]
      @class    -> merge_into(:classes, acc, val)
      @content  -> acc ++ [ content: val ]
      @tab      -> acc ++ [ indent: String.length(h) ]
    end
    parse_line(t, acc)
  end

  def build_tree([]), do: []
  def build_tree([h|t], parent_indent//0) do
    # indent = current_level(h)
    # { t, children } = cond do
    #   parent_indent < indent -> process_children(t, parent_indent)
    # end
    # [ h ++ [ children: children] ] ++ build_tree(t, indent)
  end

  # def process_children([]), do: { [], acc }
  # def process_children([h|t]) do
  #   { t, children } = pop_children(h, t)

  #   [h ++ [children: children]] ++ process_children(t)
  # end

  def pop_children(parent, list) do
    { children, rem }  = Enum.split_while(list, fn(l) -> Keyword.get(l, :indent, 0) > parent[:indent] end)
    { rem, children }
  end

  defp current_level(h), do: Keyword.get(h, :indent, 0)

  defp merge_into(key, list, value) do
    value = cond do
      list[key] -> [list[key]] ++ [value]
      true      -> [value]
    end
    Keyword.put(list, key, value) |> Enum.reverse
  end

  defp head(str), do: String.first(str)
  defp tail(str), do: String.slice(str, 1..-1)
end
