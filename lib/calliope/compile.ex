defmodule Calliope.Compiler do

  @attributes   [ :id, :classes, :attributes ]
  @self_closing [ "area", "base", "br", "col", "command", "embed", "hr", "img", "input", "keygen", "link", "meta", "param", "source", "track", "wbr" ]

  @lc ~r/^(.*)do:?(.*)$/

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
    build_html(h) <> compile(t)
  end

  defp build_html(node) do
    html = cond do
      node[:smart_script] -> evaluate_smart_script(node[:smart_script], node[:children])
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

  def evaluate_smart_script(<< "#", _ :: binary >>, _, _), do: ""
  def evaluate_smart_script(script, children) do
    smart_script_to_string(script, children)
  end

  def evaluate_script(nil), do: ""
  def evaluate_script(script) when is_binary(script), do: "<%= #{String.lstrip(script)} %>"

  defp smart_script_to_string(<< "lc", script :: binary>>, children) do
    [ _, cmd, inline, _ ] = Regex.split(@lc, script)
    """
      <%= lc#{cmd}do %>
        #{inline}
        #{compile(children)}
      <%= end %>
    """ |> String.strip
  end

  defp smart_script_to_string(script, children) do
    %{cmd: cmd, fun_sign: fun_sign, wraps_end: wraps_end} = cond do
      String.starts_with?(script, "cond") ->
        handle_cond_do(script)
      length(Regex.scan(~r/->/, script)) > 0 ->
        handle_arrow(script)
      true ->
        raise "Not implemented operator:\n #{script}"
    end

    """
      <%= #{cmd}#{fun_sign} %>
        #{compile(children)}
      #{wraps_end}
    """
    |> String.strip
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

  def comment(<<"!--" :: binary, condition :: binary>>, :open), do: "<!--#{condition}> "
  def comment(<<"!--" :: binary, _ :: binary>>, :close), do: " <![endif]-->"

  def open( _, nil), do: ""
  def open( _, <<"!!!" :: binary, key :: binary>>), do: @doctypes[:"!!!#{key}"]
  def open(attributes, tag_value), do: "<#{tag_value}#{attributes}>"

  def close(nil), do: ""
  def close(<<"!!!" :: binary, _ :: binary>>), do: ""
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

  defp handle_cond_do(script) do
    # cond or case operator DOESN'T have inline verion, e.g.: cond, do: true -> "truly"
    [ _, cmd, _] = Regex.split(~r/^(.*)do:?.*$/, script)
    %{cmd: cmd, fun_sign: "do", wraps_end: "<%= end %>"}
  end

  defp handle_arrow(script) do
    [ _, cmd, _inline, _] = Regex.split(~r/^(.*)->:?(.*)$/, script)
    %{cmd: cmd, fun_sign: "->", wraps_end: ""}
  end
end
