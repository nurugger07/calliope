defmodule Calliope.Safe do

  @doc """
  Calliope.Safe is a utility for evaluating code and escaping HTML tag
  characters.
  """

  @html_escape [
    { "&", "&amp;"},
    { "<", "&lt;" },
    { ">", "&rt;" },
    { "\"", "&quote;" },
    { "'", "&#39;" },
  ]

  def eval_safe_script("Safe.script" <> script, args) do
    evaluate_script(args, script)
  end
  def eval_safe_script(script, args) do
    clean args |> evaluate_script(script)
  end

  def evaluate_script(args, script) do
    { result, _ } = Code.string_to_quoted!(script) |> Code.eval_quoted(args)
    result
  end

  def clean(str) when is_binary(str), do: scrub(str, @html_escape)
  def clean([]), do: []
  def clean([{ arg, val} | t ]) when is_binary(val) do
    [ { arg, scrub(val, @html_escape) } | clean(t) ]
  end
  def clean([{ arg, val} | t]) when is_list(val) do
    [ { arg, scrub_list(val) } | clean(t) ]
  end

  defp scrub_list([]), do: []
  defp scrub_list([h|t]) when is_tuple(h) do
    [(Tuple.to_list(h) |> scrub_list |> List.to_tuple)] ++ scrub_list(t)
  end
  defp scrub_list([h|t]) do
    [scrub(h, @html_escape) | scrub_list(t)]
  end

  defp scrub(val, []), do: val
  defp scrub(val, [{ html, escape } | t]) do
    escape_string(val, html, escape) |> scrub(t)
  end

  defp escape_string(str, _, _) when is_integer(str), do: str
  defp escape_string(str, element, replace) do
    String.replace(str, element, replace)
  end
end
