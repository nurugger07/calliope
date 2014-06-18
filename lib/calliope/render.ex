defmodule Calliope.Render do
  import Calliope.Tokenizer
  import Calliope.Parser
  import Calliope.Compiler

  def precompile(haml) do
    tokenize(haml) |> parse |> compile
  end

  def eval(html, []), do: html
  def eval(html, args), do: EEx.eval_string(html, args)

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__
      import Calliope.Tokenizer
      import Calliope.Parser
      import Calliope.Compiler
      import Calliope.Safe

      require EEx

      def render(haml, args \\ []) do
        precompile(haml) |> eval(args)
      end

    end
  end
end
