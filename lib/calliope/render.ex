defmodule Calliope.Render do

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__
      import Calliope.Tokenizer
      import Calliope.Parser
      import Calliope.Compiler

      def render(haml, args\\[]), do: tokenize(haml) |> parse |> compile(args)
    end
  end
end
