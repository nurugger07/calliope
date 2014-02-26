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

  def eval_safe_script(<< "Safe.script", script :: binary >>, args) do
    evaluate_script(args, script)
  end
  def eval_safe_script(script, args) do
    clean args |> evaluate_script script
  end

  def evaluate_script(args, script) do
    { result, _ } = Code.string_to_quoted!(script) |> Code.eval_quoted(args)
    result
  end

  def clean(str) when is_binary(str), do: scrub(str, @html_escape)
  def clean([]), do: []
  def clean([{ arg, val} | t ]) do
    [ { arg, scrub(val, @html_escape) } ] ++ clean(t)
  end

  defp scrub(val, []), do: val
  defp scrub(val, [{ html, escape } | t]) do
    escape_string(val, html, escape) |> scrub(t)
  end

  defp escape_string(str, element, replace), do: String.replace(str, element, replace)
end
