defmodule Calliope.Parser do

  @tag      "%"
  @id       "#"
  @class    "."
  @content  " "
  @tab      "\t"

  def parse([]), do: []
  def parse(l) do
    build_tree(parse_lines(l))
  end

  def parse_lines([]), do: []
  def parse_lines([h|t]), do: [parse_line(h)|parse_lines(t)]

  def parse_line([], acc), do: acc
  def parse_line([h|t], acc//[]) do
    [sym, val] = [head(h), tail(h)]
    acc = case sym do
      @tag      -> acc ++ [ tag: val ]
      @id       -> acc ++ [ id: val ]
      @class    -> merge_into(:classes, acc, val)
      @tab      -> acc ++ [ indent: String.length(h) ]
      _         -> acc ++ [ content: String.strip(h) ]
    end
    parse_line(t, acc)
  end

  def build_tree([]), do: []
  def build_tree([h|t]) do
    {rem, children} = pop_children(h, t)
    [h ++ build_children(children)] ++ build_tree(rem)
  end

  defp build_children([]), do: []
  defp build_children(l), do: [children: build_tree(l)]

  def pop_children(parent, list) do
    { children, rem }  = Enum.split_while(list, &bigger_indentation?(&1, parent))
    { rem, children }
  end

  defp bigger_indentation?(token1, token2) do
    Keyword.get(token1, :indent, 0) > Keyword.get(token2, :indent, 0)
  end

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
