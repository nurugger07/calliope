defmodule Calliope.Render do

  import Calliope.Tokenizer
  import Calliope.Parser
  import Calliope.Compiler

  def render(haml, args//[]), do: tokenize(haml) |> parse |> compile(args)

end
