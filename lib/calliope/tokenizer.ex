defmodule Calliope.Tokenizer do

  @indent       ~S/(^[\t ]+)|(\/\s)|(\/\[\w+])/
  @tag_class_id ~S/([%.#][-:\w]+)/
  @keyword      ~S/[-:\w]+/
  @value        ~S/(?:(?:'.*?')|(?:".*?"))/
  @hash_param   ~s/\\s*#{@keyword}:\\s*#{@value}\\s*/
  @hash_params  ~s/({#{@hash_param}(?:,#{@hash_param})*?})/
  @h_r_param    ~s/\\s*:[-\\w]+?\\s+?=\\>\\s+?#{@value}\\s*/
  @h_r_params   ~s/({#{@h_r_param}(?:,#{@h_r_param})*?})/
  @html_param   ~s/\\s*#{@keyword}\\s*=\\s*#{@value}\\s*/
  @html_params  ~s/(\\(#{@html_param}(?:\\s#{@html_param})*?\\))/
  @rest         ~S/(.+)/

  @regex        ~r/(?:#{@indent}|#{@tag_class_id}|#{@hash_params}|#{@h_r_params}|#{@html_params}|#{@rest})/

  def tokenize(haml) when is_binary(haml) do
    Regex.split(~r/\n/, haml, trim: true) |> tokenize |> tokenize_identation |> index
  end

  def tokenize([]), do: []
  def tokenize([h|t]) do
    [tokenize_line(h) | tokenize(t)]
  end

  def tokenize_line(line) do
    Regex.scan(@regex, line, trim: true) |> reduce
    |> Enum.map(fn(t) ->
      s = String.split(t, ~r/(}|\))\s*=/)
      case s do
        [tag, content] -> [tag <> "}", "=" <> content]
        _ -> s
      end
    end)
    |> List.flatten
    |> Enum.map(fn(t) ->
      case String.starts_with?(t, "-") do
        false ->
          s = String.split(t, ~r/(}|\))\s+/i)
          case s do
            [tag, content] -> [tag <> "}", " " <> content]
            _ -> s
          end
        true -> t
      end
    end)
    |> List.flatten
  end

  def reduce([]), do: []
  def reduce([h|t]) do
    [Enum.reverse(h) |> hd | reduce(t)]
  end

  def tokenize_identation(list), do: tokenize_identation(list, compute_tabs(list))
  def tokenize_identation([], _), do: []
  def tokenize_identation([h|t], spacing) do
    [head|tail] = h
    new_head = cond do
      Regex.match?(~r/^ +$/, head) -> [replace_with_tabs(head, spacing) | tail]
      true -> h
    end

    [new_head | tokenize_identation(t, spacing)]
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

  def index(list, i\\1)
  def index([], _), do: []
  def index([h|t], i), do: [[i | h] | index(t, i+1)]

end
