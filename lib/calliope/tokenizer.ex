defmodule Calliope.Tokenizer do

  @regex  ~r/(?:(^[\t| ]+)|(\/\s)|(\/\[\w+])|([%.#][-:\w]+)|([{(].+?['"][)}])|(.+))\s*/

  def tokenize(haml) when is_binary(haml) do
    Regex.split(~r/\n/, haml) |> tokenize |> filter |> tokenize_identation |> index
  end

  def tokenize([]), do: []
  def tokenize([h|t]) do
    [tokenize_line(h)] ++ tokenize(t)
  end

  defp filter(list), do: Enum.filter(list, fn(x) -> x != [] end)

  def tokenize_line(line) do
    Regex.split(@regex, line, trim: true)
  end

  def tokenize_identation(list), do: tokenize_identation(list, compute_tabs(list))
  def tokenize_identation([], _), do: []
  def tokenize_identation([h|t], spacing) do
    [head|tail] = h
    new_head = cond do
      Regex.match?(~r/^ +$/, head) -> [replace_with_tabs(head, spacing)] ++ tail
      true -> h
    end

    [new_head] ++ tokenize_identation(t, spacing)
  end

  defp replace_with_tabs(empty_str, spacing) do
    div(String.length(empty_str), spacing) |> add_tab
  end

  def compute_tabs([]), do: 0
  def compute_tabs([h|t]) do
    [head|_] = h
    cond do
      Regex.match?(~r/^ +$/, head) -> String.length head
      true -> compute_tabs(t)
    end
  end

  defp add_tab(n), do: add_tab(n, "")
  defp add_tab(0, acc), do: acc
  defp add_tab(n, acc), do: add_tab(n-1, "\t" <> acc)

  def index([], _), do: []
  def index([h|t], i\\1), do: [[i] ++ h] ++ index(t, i+1)

end
