defmodule Calliope.Compiler do

  @attributes   [ :id, :classes, :attributes ]
  @self_closing [ "area", "base", "br", "col", "command", "embed", "hr", "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr" ]

  @doctypes [
    { :"!!!", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" },
    { :"!!! 5", "<!DOCTYPE html>" },
    { :"!!! Strict", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">" },
    { :"!!! Frameset", "<!DOCTYPE html PUBLIC \"W3C//DTD XHTML 1.0 Frameset//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd\">" },
    { :"!!! 1.1", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">" },
    { :"!!! Basic", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML Basic 1.1//EN\" \"http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd\">" },
    { :"!!! Mobile", "<!DOCTYPE html PUBLIC \"-//WAPFORUM//DTD XHTML Mobile 1.2//EN\" \"http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd\">" },
    { :"!!! RDFa", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML+RDFa 1.0//EN\" \"http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd\">" }
  ]

  def compile([]), do: ""
  def compile(nil), do: ""
  def compile([h|t]) do
    open(compile_attributes(h), tag(h)) <> "#{h[:content]}" <> compile(h[:children]) <> close(tag(h)) <> compile(t)
  end

  def open( _, nil), do: ""
  def open( _, <<"!!!" :: binary, key :: binary>>), do: @doctypes[:"!!!#{key}"]
  def open(attributes, tag_value), do: "<#{tag_value}#{attributes}>"

  def close(nil), do: ""
  def close(<<"!!!" :: binary, _ :: binary>>), do: ""
  def close(tag_value) when tag_value in @self_closing, do: ""
  def close(tag_value), do: "</#{tag_value}>"

  def compile_attributes(list) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1]))
  end

  def reject_or_compile_key( _, nil), do: nil
  def reject_or_compile_key(key, value), do: compile_key({ key, value })

  def compile_key({ :attributes, value }), do: " #{value}"
  def compile_key({ :classes, value}), do: " class=\"#{Enum.join(value)}\""
  def compile_key({ :id, value }), do: " id=\"#{value}\""

  def tag(node) do
    cond do
      has_any_key?(node, [:doctype]) -> Keyword.get(node, :doctype)
      has_any_key?(node, [:tag]) -> Keyword.get(node, :tag)
      has_any_key?(node, [:tag]) -> Keyword.get(node, :tag)
      has_any_key?(node, [:id, :classes]) -> "div"
      has_any_key?(node, [:content]) -> nil
      true -> false #raise an error
    end
  end

  defp has_any_key?( _, []), do: false
  defp has_any_key?(list, [h|t]), do: Keyword.has_key?(list, h) || has_any_key?(list, t)

end
