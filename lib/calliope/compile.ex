defmodule Calliope.Compiler do

  @attributes [ :id, :classes, :attributes ]

  def compile([]), do: ""
  def compile(nil), do: ""
  def compile([h|t]) do
    open(compile_attributes(h), tag(h)) <> "#{h[:content]}" <> compile(h[:children]) <> close(tag(h)) <> compile(t)
  end

  def open( _, nil, _), do: ""
  def open(attributes//"", tag_value, indent//[]) do
    (indent ++ ["<#{tag_value}", "#{attributes}>"]) |> join
  end

  def close( nil, _), do: ""
  def close(tag_value, indent//[]), do: (indent ++ ["</#{tag_value}>"]) |> join

  def compile_attributes(list) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1]))
  end

  def reject_or_compile_key(_, nil), do: nil
  def reject_or_compile_key(key, value), do: compile_key({ key, value })

  def compile_key({ :classes, value}), do: " class=\"#{join(value, " ")}\""
  def compile_key({ :id, value }), do: " id=\"#{value}\""

  def tag(node) do
    cond do
      Keyword.has_key?(node, :tag) -> Keyword.get(node, :tag)
      Keyword.has_key?(node, :id) ||
        Keyword.has_key?(node, :classes) -> "div"
      Keyword.has_key?(node, :content) -> nil
      true -> false #raise an error
    end
  end

  def indents(0, tabs), do: [Enum.join(tabs)]
  def indents(n, tabs//[]), do: indents(n - 1, tabs ++ ["\t"])

  defp join(list, sep//""), do: Enum.join(list, sep)
end
