defmodule CalliopeException do
  defexception [:message]

  def messages do
    [
      too_deep_indent:        "Indentation was too deep on line number: #",
      unknown_filter:         "Unknown filter on line number: #",
      multiple_ids_assigned:  "tag id is assigned multiple times on line number #",
      invalid_attribute:      "Invalid attribute '##data##' on line number #`",
      unknown:                "Something wicked this way comes"
    ]
  end

  def exception(opts) do
    error = error_message(opts)
    line = line_number(opts)
    data = get_data(opts)

    %CalliopeException{message: build_message(error, line, data)}
  end

  defp build_message(error, line, data) do 
    messages()[error] 
    |> String.replace(~r/##data##/, data)
    |> String.replace(~r/#/, "#{line}")
  end
  defp error_message(opts), do: opts[:error] || :unknown
  defp line_number(opts), do: opts[:line] || "unknown"
  defp get_data(opts), do: opts[:data] || ""

end
