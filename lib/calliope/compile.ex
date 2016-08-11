defmodule Calliope.Compiler do

  @nl "\n"
  @indent_size 2
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

  def compile(list, smart_indent \\ 0)
  def compile([], _si), do: ""
  def compile(nil, _si), do: ""
  def compile([h|t], si) do
    build_html(h,t, si) <> compile(t, si)
  end

  defp build_html(node, [], si) do
    build_html(node, [[]], si)
  end
  defp build_html(node, [next_node|_], si) do
    cond do
      node[:smart_script] ->
        cond do
          next_node[:smart_script] ->
            # send next code to look ahead for things like else
            evaluate_smart_script(node[:smart_script], node[:children], next_node[:smart_script], si)
          true ->
            evaluate_smart_script(node[:smart_script], node[:children], "", si)
        end
      true -> evaluate(node, si)
    end
  end

  def evaluate(line, si) do
    leader(line, si) <>
    comment(line[:comment], :open) <>
      open(compile_attributes(line), tag(line)) <>
        add_newline(line) <>
        precompile_content("#{line[:content]}") <>
        evaluate_script(line[:script]) <>
        compile(line[:children], si) <>
      close_script(line[:script]) <>
      close(tag(line), leader_close(line, si)) <>
    comment(line[:comment], :close) <> @nl
  end

  defp add_newline(line) do
    case line[:children] do
      nil -> ""
      [] -> ""
      _ -> @nl
    end
  end

  defp leader(line, si) do
    case line[:indent] do
      nil   -> ""
      value -> String.rjust("", (value - si) * @indent_size)
    end
  end

  defp leader_close(line, si) do
    case line[:children] do
      nil -> ""
      []  -> ""
      _   -> leader(line, si)
    end
  end

  def evaluate_smart_script("#" <> _, _, _, _), do: ""
  def evaluate_smart_script(script, children, next_node, si) do
    smart_script_to_string(script, children, next_node, si)
  end

  def evaluate_script(nil), do: ""
  def evaluate_script(script) when is_binary(script), do: "<%= #{String.lstrip(script)} %>"

  defp smart_script_to_string("if" <> script, children, "else", si) do
    %{cmd: cmd, end_tag: end_tag} = handle_script("if" <> script)
    "<%= #{cmd} #{end_tag}" <> smart_children(children, si + 1)
  end
  defp smart_script_to_string("unless" <> script, children, "else", si) do
    %{cmd: cmd, end_tag: end_tag} = handle_script("unless" <> script)
    "<%= #{cmd} #{end_tag}" <> smart_children(children, si + 1)
  end
  defp smart_script_to_string("else", children, _, si) do
    %{cmd: cmd, end_tag: end_tag} = handle_script("else")
    "<% #{cmd} #{end_tag}" <> smart_children(children, si + 1) <> "<% end %>"
  end

  defp smart_script_to_string(script, children, _, si) do
    %{cmd: cmd, wraps_end: wraps_end, open_tag: open_tag,
      end_tag: end_tag} = handle_script(script)
    "#{open_tag} #{cmd} #{end_tag}" <> smart_children(children, si + 1) <> smart_wraps_end(wraps_end)
  end

  defp smart_children(nil, _), do: ""
  defp smart_children([], _), do: ""
  defp smart_children(children, si), do: "\n#{compile children, si}"

  defp smart_wraps_end(""), do: ""
  defp smart_wraps_end(nil), do: ""
  defp smart_wraps_end(wraps_end), do: "\n#{wraps_end}"

  def precompile_content(nil), do: nil
  def precompile_content(content) do
    Regex.scan(~r/\#{(.+)}/U, content) |>
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

  def close(tag, leader \\ "")
  def close(nil, _leader), do: ""
  def close("!!!" <> _, _leader), do: ""
  def close(tag_value, _leader) when tag_value in @self_closing, do: ""
  def close(tag_value, leader), do: leader <> "</#{tag_value}>"

  def close_script(nil), do: ""
  def close_script(script) do
    cond do
      Regex.match?(~r/do\s*\z/, script) -> "<% end %>"
      true -> ""
    end
  end

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
    ch = if Regex.match?(~r/^[A-Za-z0-9\?!_\.]+\(/, script), do: ")", else: ""
    cond do
      Regex.match? ~r/(fn )|(fn\()[a-zA-Z0-9,\) ]+->/, script ->
        %{cmd: script, wraps_end: "<% end#{ch} %>", end_tag: "%>", open_tag: "<%="}
      Regex.match? ~r/ do:?/, script ->
        %{cmd: script, wraps_end: "<% end#{ch} %>", end_tag: "%>", open_tag: "<%="}
      true ->
        %{cmd: script, wraps_end: "", end_tag: "%>", open_tag: "<%"}
    end
  end
end
