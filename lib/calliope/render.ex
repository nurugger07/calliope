defmodule Calliope.Render do

  import Calliope.Tokenizer
  import Calliope.Parser
  import Calliope.Compiler

  def render(haml), do: tokenize(haml) |> parse |> compile

end
