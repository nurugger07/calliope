defmodule Calliope.Mixfile do
  use Mix.Project

  def project do
    [ app: :calliope,
      version: "0.2.0",
      elixir: "~> 0.12.0",
      deps: deps ]
  end

  def application do
    []
  end

  defp deps do
    []
  end
end
