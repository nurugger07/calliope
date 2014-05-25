defmodule CalliopeException do
  defexception [:message]

  def messages do
    [
      too_deep_indent:        "Indentation was too deep on line number: #",
      multiple_ids_assigned:  "tag id is assigned multiple times on line number #",
      unknown:                "Something wicked this way comes"
    ]
  end

  def exception(opts) do
    error = error_message(opts)
    line = line_number(opts)

    %CalliopeException{message: build_message(error, line)}
  end

  defp build_message(error, line), do: Regex.replace(~r/#/, messages[error], "#{line}")
  defp error_message(opts), do: opts[:error] || :unknown
  defp line_number(opts), do: opts[:line] || "unknown"

end
