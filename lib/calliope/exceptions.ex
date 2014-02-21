defexception CalliopeException, [:message] do

  def messages do
    [
      bad_script_indent: "tag is indented at wrong level on line number: #",
      invalid_attribute_list: "Invalid attributes on line number: #",
      unknown: "Something wicked this way comes"
    ]
  end

  def exception(opts) do
    error = error_message(opts)
    line = line_number(opts)

    CalliopeException[message: build_message(error, line)]
  end

  defp build_message(error, line), do: Regex.replace(~r/#/, messages[error], "#{line}")
  defp error_message(opts), do: opts[:error] || :unknown
  defp line_number(opts), do: opts[:line] || "unknown"

end
