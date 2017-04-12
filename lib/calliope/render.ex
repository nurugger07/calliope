defmodule Calliope.Render do
  import Calliope.Tokenizer
  import Calliope.Parser
  import Calliope.Compiler
  import Calliope.Safe

  def precompile(haml) do
    tokenize(haml) |> parse |> compile
  end

  def eval(html, []), do: html
  def eval(html, args), do: EEx.eval_string(html, maybe_escape(args))

  defp maybe_escape(args) do
    cond do
      args[:_safe] ->
        Enum.map(
          args,
          fn {k, v} when is_binary(v) -> {k, clean(v) }
             {k, v} -> {k, v}
          end
        )
      true ->
        args
    end
  end

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
