defmodule Calliope.Parser do

  @tag      "%"
  @id       "#"
  @class    "."
  @content  " "
  @tab      "\t"
  @doctype  "!"
  @attrs    "{"
  @parens   "("
  @comment  "/"
  @script   "="
  @smart    "-"

  def parse([]), do: []
  def parse(l) do
    parse_lines(l) |> validations |> build_tree
  end

  def parse_lines([]), do: []
  def parse_lines([h|t]), do: [parse_line(h)|parse_lines(t)]

  def parse_line([], acc), do: acc
  def parse_line([h|t], acc) when is_integer(h) do
    parse_line(t, acc ++ [line_number: h])
  end
  def parse_line([h|t], acc\\[]) do
    [sym, val] = [head(h), tail(h)]
    acc = case sym do
      @doctype  -> acc ++ [ doctype: h ]
      @tag      -> acc ++ [ tag: val ]
      @id       -> handle_id(acc, val)
      @class    -> merge_into(:classes, acc, [val])
      @tab      -> acc ++ [ indent: String.length(h) ]
      @attrs    -> merge_attributes( acc, val)
      @parens   -> merge_attributes( acc, val)
      @comment  -> acc ++ handle_comment(val)
      @script   -> acc ++ [ script: val ]
      @smart    -> acc ++ [ smart_script: String.strip(val) ]
      _         -> acc ++ [ content: String.strip(h) ]
    end
    parse_line(t, acc)
  end

  def handle_comment(val), do: [ comment: String.rstrip "!--#{val}" ]
  def handle_id(line, id) do
    cond do
      line[:id] -> raise_error :multiple_ids_assigned, line[:line_number]
      true -> line ++ [ id: id ]
    end
  end

  def build_attributes(value) do
    String.slice(value, 0, String.length(value)-1) |>
      String.replace(~r/class[=:]\s?['"](.*)['"]/r, "") |>
      String.replace(~r/id[=:]\s?['"](.*)['"]/r, "") |>
      String.replace(~r/:\s([\'"])/, "=\\1") |>
      String.replace(~r/:\s(\w+)\s?/, "='\#{\\1}'") |>
      String.replace(~r/,\s?/, " ") |>
      String.strip
  end

  def build_tree([]), do: []
  def build_tree([h|t]) do
    {rem, children} = pop_children(h, t)
    [h ++ build_children(children)] ++ build_tree(rem)
  end

  defp build_children([]), do: []
  defp build_children(l), do: [children: build_tree(l)]

  defp pop_children(parent, list) do
    { children, rem }  = Enum.split_while(list, &bigger_indentation?(&1, parent))
    { rem, children }
  end

  defp bigger_indentation?(token1, token2) do
    Keyword.get(token1, :indent, 0) > Keyword.get(token2, :indent, 0)
  end

  defp merge_attributes(list, << "{", value :: binary >>) do
    list ++ [content: "{{#{value}"]
  end
  defp merge_attributes(list, value) do
    classes = extract(:class, value)
    id = extract(:id, value)
    attributes = build_attributes(value)

    merge_into(:classes, merge_into(:id, list, id), classes) ++ [attributes: attributes ]
  end

  defp extract(key, str) do
    case Regex.run(~r/#{key}[=:]\s?['\"](.*)['"]/r, str) do
      [ _, match | _ ] -> String.split match
      _ -> []
    end
  end

  defp merge_into(:id, list, []), do: list
  defp merge_into(:id, list, [h|_]), do: list ++ [ id: h ]

  defp merge_into(_, list, []), do: list
  defp merge_into(key, list, value) do
    value = cond do
      list[key] -> list[key] ++ value
      true      -> value
    end
    Keyword.put(list, key, value) |> Enum.reverse
  end

  defp head(str), do: String.first(str)
  defp tail(str), do: String.slice(str, 1..-1)

  defp validations([]), do: []
  defp validations([h|t]) do
    next = List.first(t)
    cond do
      invalid_indentation?(h, next) -> raise_error(:too_deep_indent, next[:line_number])
      true -> [h] ++ validations(t)
    end
  end

  defp invalid_indentation?(_, nil), do: false
  defp invalid_indentation?(parent, child) do
    Keyword.get(child, :indent, 0) > Keyword.get(parent, :indent, 0) + 1 
  end

  defp raise_error(error, line), do: raise(CalliopeException, error: error, line: line)
end
