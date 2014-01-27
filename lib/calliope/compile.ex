defmodule Calliope.Compiler do

  @attributes   [ :id, :classes, :attributes ]
  @self_closing [ "area", "base", "br", "col", "command", "embed", "hr", "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr" ]

  def compile([]), do: ""
  def compile(nil), do: ""
  def compile([h|t]) do
    open(compile_attributes(h), tag(h)) <> "#{h[:content]}" <> compile(h[:children]) <> close(tag(h)) <> compile(t)
  end

  def open(_, nil), do: ""
  def open(attributes, tag_value), do: "<#{tag_value}#{attributes}>"

  def close(nil), do: ""
  def close(tag_value) when tag_value in @self_closing, do: ""
  def close(tag_value), do: "</#{tag_value}>"

  def compile_attributes(list) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1]))
  end

  def reject_or_compile_key(_, nil), do: nil
  def reject_or_compile_key(key, value), do: compile_key({ key, value })

  def compile_key({ :classes, value}), do: " class=\"#{Enum.join(value)}\""
  def compile_key({ :id, value }), do: " id=\"#{value}\""

  def tag(node) do
    cond do
      has_any_key?(node, [:tag]) -> Keyword.get(node, :tag)
      has_any_key?(node, [:id, :classes]) -> "div"
      has_any_key?(node, [:content]) -> nil
      true -> false #raise an error
    end
  end

  defp has_any_key?(_, []), do: false
  defp has_any_key?(list, [h|t]), do: Keyword.has_key?(list, h) || has_any_key?(list, t)

end
