defmodule Calliope.Compiler do

  @attributes   [ :id, :classes, :attributes ]
  @self_closing [ "area", "base", "br", "col", "command", "embed", "hr", "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr" ]

  @doctypes [
    { :"!!!", "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">"},
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
    build_html(h,t) <> compile(t)
  end

  defp build_html(node, []) do
    build_html(node, [[]])
  end
  defp build_html(node, [next_node|_]) do
    cond do
      node[:smart_script] -> 
        cond do
          next_node[:smart_script] ->
            # send next code to look ahead for things like else
            evaluate_smart_script(node[:smart_script], node[:children], next_node[:smart_script])
          true ->  
            evaluate_smart_script(node[:smart_script], node[:children], "")
        end
      true -> evaluate(node)
    end
  end

  def evaluate(line) do
    comment(line[:comment], :open) <>
      open(compile_attributes(line), tag(line)) <>
        precompile_content("#{line[:content]}") <>
        evaluate_script(line[:script]) <>
        compile(line[:children]) <>      
      close(tag(line)) <>
    comment(line[:comment], :close)
  end

  def evaluate_smart_script("#" <> _, _, _), do: ""
  def evaluate_smart_script(script, children, next_node) do
    smart_script_to_string(script, children, next_node)
  end

  def evaluate_script(nil), do: ""
  def evaluate_script(script) when is_binary(script), do: "<%= #{String.lstrip(script)} %>"

  defp smart_script_to_string("if" <> script, children, "else") do
    %{cmd: cmd, end_tag: end_tag} = handle_script("if" <> script)
    """
    <%= #{cmd} #{end_tag}
      #{compile children}
    """
  end
  defp smart_script_to_string("unless" <> script, children, "else") do
    %{cmd: cmd, end_tag: end_tag} = handle_script("unless" <> script)
    """
    <%= #{cmd} #{end_tag}
      #{compile children}
    """
  end
  defp smart_script_to_string("else", children, _) do
    %{cmd: cmd, end_tag: end_tag} = handle_script("else")
    """
    <% #{cmd} #{end_tag}
      #{compile children}
    <% end %>
    """
  end

  defp smart_script_to_string(script, children, _ ) do
    %{cmd: cmd, wraps_end: wraps_end, open_tag: open_tag,
      end_tag: end_tag} = handle_script(script)
    """
    #{open_tag} #{cmd} #{end_tag}
      #{compile children}
    #{wraps_end}
    """
  end

  def precompile_content(nil), do: nil
  def precompile_content(content) do
    Regex.scan(~r/\#{(.+)}/r, content) |>
      map_content_to_args(content)
  end

  defp map_content_to_args([], content), do: content
  defp map_content_to_args([[key, val]|t], content) do
    map_content_to_args(t, String.replace(content, key, "<%= #{val} %>"))
  end

  def comment(nil, _), do: ""
  def comment("!--", :open), do: "<!-- "
  def comment("!--", :close), do: " -->"

  def comment("!--" <> condition, :open), do: "<!--#{condition}> "
  def comment("!--" <> _, :close), do: " <![endif]-->"

  def open( _, nil), do: ""
  def open( _, "!!!" <> key), do: @doctypes[:"!!!#{key}"]
  def open(attributes, tag_value), do: "<#{tag_value}#{attributes}>"

  def close(nil), do: ""
  def close("!!!" <> _), do: ""
  def close(tag_value) when tag_value in @self_closing, do: ""
  def close(tag_value), do: "</#{tag_value}>"

  def compile_attributes(list) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1])) |>
      precompile_content |>
      String.rstrip
  end

  def reject_or_compile_key( _, nil), do: nil
  def reject_or_compile_key(key, value), do: compile_key({ key, value })

  def compile_key({ :attributes, value }), do: " #{value}"
  def compile_key({ :classes, value}), do: " class=\"#{Enum.join(value, " ")}\""

  def compile_key({ :id, value }), do: " id=\"#{value}\""

  def tag(node) do
    cond do
      has_any_key?(node, [:doctype]) -> Keyword.get(node, :doctype)
      has_any_key?(node, [:tag]) -> Keyword.get(node, :tag)
      has_any_key?(node, [:id, :classes]) -> "div"
      has_any_key?(node, [:content]) -> nil
      true -> nil
    end
  end

  defp has_any_key?( _, []), do: false
  defp has_any_key?(list, [h|t]), do: Keyword.has_key?(list, h) || has_any_key?(list, t)

  defp handle_script(script) do
    cond do
      Regex.match? ~r/(fn )|(fn\()[a-zA-Z0-9,\) ]+->/, script ->
        %{cmd: script, wraps_end: "end) %>", end_tag: "\n", open_tag: "<%="}
      Regex.match? ~r/ do:?/, script -> 
        %{cmd: script, wraps_end: "<% end %>", end_tag: "%>", open_tag: "<%="}
      true ->
        %{cmd: script, wraps_end: "", end_tag: "%>", open_tag: "<%"}
    end
  end
end
