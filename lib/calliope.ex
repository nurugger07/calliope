defmodule Calliope do
  use Calliope.Render

  defmacro __using__([]) do
    quote do
      import unquote __MODULE__

      use Calliope.Render
    end
  end
end
