defmodule Calliope.Tokenizer do

  def tokenize(haml) when is_binary(haml) do
    Regex.split(%r/\n/, haml) |> tokenize
  end

  def tokenize([]), do: []
  def tokenize([h|t]) do
    [tokenize_line(h)] ++ tokenize(t)
  end

  def tokenize_line(line) do
    Regex.split(%r/(?:(^[\t]+)|([%.#][-:\w]+))\s*/, line, trim: true)
  end
end
