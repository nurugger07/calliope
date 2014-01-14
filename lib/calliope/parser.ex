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

  def merge_into(key, list, value) do
    value = cond do
      list[key] -> [list[key]] ++ [value]
      true -> [value]
    end
    Keyword.put(list, key, value) |> Enum.reverse
  end

  defp head(str), do: String.first(str)
  defp tail(str), do: String.slice(str, 1..-1)
end
