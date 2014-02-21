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

  def compile([], _), do: ""
  def compile(nil, _), do: ""
  def compile([h|t], args\\[]) do
    haml = cond do
      h[:smart_script] -> evaluate_smart_script(h[:smart_script], h[:children], args)
      true -> evaluate(h, args)
    end
    haml <> compile(t, args)
  end

  def evaluate(line, args) do
    comment(line[:comment], :open) <>
      open(compile_attributes(line, args), tag(line)) <>
        evaluate_content("#{line[:content]}", args) <>
        evaluate_script(line[:script], args) <>
        compile(line[:children], args) <>
      close(tag(line)) <>
    comment(line[:comment], :close)
  end

  def evaluate_smart_script(<< "#", _ :: binary >>, _, _), do: ""
  def evaluate_smart_script(script, children, args) do
    { { :ok, result }, _ } = compile_quoted(script, children) |> Code.eval_quoted(args)
    Enum.join(result)
  end

  def evaluate_script(nil, _), do: ""
  def evaluate_script(script, []), do: "\#{#{script}}"
  def evaluate_script(script, args) do
    {result, _} = Code.eval_string(script, args)
    result
  end

  defp compile_quoted(<< "lc", script :: binary>>, children) do
    [ _, cmd, inline, _ ] = Regex.split(@lc, script)
    Code.string_to_quoted """
      lc #{cmd} do
        #{inline}
        "#{compile(children)}"
      end
    """
  end

  def evaluate_content(nil, _), do: nil
  def evaluate_content(content, []), do: content
  def evaluate_content(content, args\\[]) do
    Regex.scan(~r/\#{(.+)}/r, content) |>
      map_content_to_args(content, args)
  end

  defp map_content_to_args([], content, _), do: content
  defp map_content_to_args([[key, val]|t], content, args) do
    map_content_to_args(t, String.replace(content, key, evaluate_script(val, args)), args)
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

  def compile_attributes(list, []) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1])) |>
      String.rstrip
  end
  def compile_attributes(list, args) do
    Enum.map_join(@attributes, &reject_or_compile_key(&1, list[&1])) |>
      evaluate_content(args) |>
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
      has_any_key?(node, [:tag]) -> Keyword.get(node, :tag)
      has_any_key?(node, [:id, :classes]) -> "div"
      has_any_key?(node, [:content]) -> nil
      true -> nil
    end
  end

  defp has_any_key?( _, []), do: false
  defp has_any_key?(list, [h|t]), do: Keyword.has_key?(list, h) || has_any_key?(list, t)

end
