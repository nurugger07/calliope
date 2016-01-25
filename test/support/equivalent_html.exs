defmodule Support.EquivalentHtml do
  def equivalent_html?(html1, html2) do
    stripped(html1) == stripped(html2)
  end

  defp stripped(html) do
    Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, html, "")
  end
end
