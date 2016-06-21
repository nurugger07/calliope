defmodule Support.EquivalentHtml do
  import ExUnit.Assertions, only: [assert: 1, assert: 2]

  def assert_equivalent_html(html1, html2) do
    assert(stripped(html1) == stripped(html2))
  end

  defp stripped(html) do
    Regex.replace(~r/(^\s*)|(\s+$)|(\n)/m, html, "")
  end
end
