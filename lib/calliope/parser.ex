defmodule Calliope.Parser do
  @moduledoc false

  @tag "%"
  @id "#"
  @class "."
  @tab "\t"
  @doctype "!"
  @attrs "{"
  @parens "("
  @comment "/"
  @script "="
  @smart "-"
  @filter ":"

  def parse([]), do: []

  def parse(lines) do
    lines
    |> parse_lines()
    |> validations()
    |> build_tree()
  end

  def parse_lines([]), do: []
  def parse_lines([h | t]), do: [parse_line(h) | parse_lines(t)]

  def parse_line(list, acc \\ [])
  def parse_line([], acc), do: acc

  def parse_line([h | t], acc) when is_integer(h) do
    parse_line(t, [line_number: h] ++ acc)
  end

  def parse_line([h | t], acc) do
    [sym, val] = [head(h), tail(h)]
    acc = accumulate(h, sym, val, acc)

    parse_line(t, acc)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp accumulate(h, sym, val, acc) do
    case sym do
      @doctype -> [doctype: h] ++ acc
      @tag -> [tag: String.trim(val)] ++ acc
      @id -> handle_id(acc, val)
      @class -> merge_into(:classes, acc, [val])
      @tab -> [indent: String.length(h)] ++ acc
      @attrs -> merge_attributes(acc, val)
      @parens -> merge_attributes(acc, val)
      @comment -> handle_comment(val) ++ acc
      @script -> [script: val] ++ acc
      @smart -> [smart_script: String.trim(val)] ++ acc
      @filter -> handle_filter(acc, val)
      _ -> [content: String.trim(h)] ++ acc
    end
  end
  # credo:enable Credo.Check.Refactor.CyclomaticComplexity

  def handle_comment(val), do: [comment: String.trim_trailing("!--#{val}")]

  def handle_id(line, id) do
    if line[:id] do
      raise_error(:multiple_ids_assigned, line[:line_number])
    else
      [id: id] ++ line
    end
  end

  def handle_filter(line, "javascript") do
    [tag: "script", attributes: "type=\"text/javascript\""] ++ line
  end

  def handle_filter(line, "css") do
    [tag: "style", attributes: "type=\"text/css\""] ++ line
  end

  def handle_filter(line, _unknown_filter) do
    raise_error(:unknown_filter, line[:line_number])
  end

  def build_attributes(value) do
    value
    |> String.slice(0, String.length(value) - 1)
    |> String.replace(~r/(?<![-_])class[=:]\s?['"](.*)['"]/U, "")
    |> String.replace(~r/(?<![-_])id[=:]\s?['"](.*)['"]/U, "")
    |> String.replace(~r/:\s+([\'"])/, "=\\1")
    |> String.replace(~r/[:=]\s?(?!.*["'])(@?\w+)\s?/, "='#\{\\1}'")
    |> String.replace(~r/[})]$/, "")
    |> String.replace(~r/"(.+?)"\s=>\s(@?\w+)\s?/, "\\1='#\{\\2}'")
    |> String.replace(~r/:(.+?)\s=>\s['"](.*)['"]\s?/, "\\1='\\2'")
    |> filter_commas()
    |> String.trim()
  end

  @empty_param ~S/^\s*?[-\w]+?\s*?$/
  @empty_params ~s/(#{@empty_param})+?/
  @param1 ~S/[-\w]+?\s*?=\s*?['"].*?['"]\s*?/
  @params ~s/(#{@param1})+?/
  @validate ~s/^(#{@params})|(#{@empty_params})$/

  def validate_attributes(attributes) do
    if Regex.match?(~r/#{@validate}/, attributes) || attributes == "" do
      {:ok, attributes}
    else
      {:error, attributes}
    end
  end

  @wraps [?', ?"]

  def filter_commas(string) do
    state =
      string
      |> String.to_charlist()
      |> Enum.reduce(%{buffer: [], closing: false}, fn ch, state ->
        {char, closing} =
          case {ch, state[:closing]} do
            {ch, false} when ch in @wraps -> {ch, ch}
            {ch, closing} when ch == closing -> {ch, false}
            {?,, false} -> {0, false}
            {?,, closing} -> {?,, closing}
            {ch, closing} -> {ch, closing}
          end

        buffer = if char == 0, do: state[:buffer], else: [char | state[:buffer]]
        %{buffer: buffer, closing: closing}
      end)

    state[:buffer]
    |> Enum.reverse()
    |> List.to_string()
  end

  def build_tree([]), do: []

  def build_tree([h | t]) do
    {rem, children} = pop_children(h, t)
    [h ++ build_children(children)] ++ build_tree(rem)
  end

  defp build_children([]), do: []
  defp build_children(l), do: [children: build_tree(l)]

  defp pop_children(parent, list) do
    {children, rem} = Enum.split_while(list, &bigger_indentation?(&1, parent))
    {rem, children}
  end

  defp bigger_indentation?(token1, token2) do
    Keyword.get(token1, :indent, 0) > Keyword.get(token2, :indent, 0)
  end

  defp merge_attributes(list, "{" <> value) do
    [content: "{{#{value}"] ++ list
  end

  defp merge_attributes(list, value) do
    classes = extract(:class, value)
    id = extract(:id, value)

    attributes =
      case build_attributes(value) |> validate_attributes do
        {:ok, attrs} ->
          attrs

        {:error, attrs} ->
          raise_error(:invalid_attribute, list[:line_number], attrs)
      end

    [attributes: attributes] ++ merge_into(:classes, merge_into(:id, list, id), classes)
  end

  defp extract(_, nil), do: []

  defp extract(key, str) do
    case Regex.run(~r/(?<![-_])#{key}[=:]\s?['"](.*)['"]/U, str) do
      [_, match | _] -> String.split(match)
      _ -> []
    end
  end

  defp merge_into(:id, list, []), do: list
  defp merge_into(:id, list, [h | _]), do: [id: h] ++ list

  defp merge_into(_, list, []), do: list

  defp merge_into(key, list, value) do
    base = list[key] || []
    value = base ++ value

    Keyword.put(list, key, value) |> Enum.reverse()
  end

  defp head(str), do: String.first(str)
  defp tail(str), do: String.slice(str, 1..-1//1)

  defp validations([]), do: []

  defp validations([h | t]) do
    next = List.first(t)

    if invalid_indentation?(h, next) do
      raise_error(:too_deep_indent, next[:line_number])
    else
      [h | validations(t)]
    end
  end

  defp invalid_indentation?(_, nil), do: false

  defp invalid_indentation?(parent, child) do
    Keyword.get(child, :indent, 0) > Keyword.get(parent, :indent, 0) + 1
  end

  defp raise_error(error, line, data \\ nil),
    do: raise(CalliopeException, error: error, line: line, data: data)
end
