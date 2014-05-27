Code.ensure_loaded?(Hex) and Hex.start

defmodule Calliope.Mixfile do
  use Mix.Project

  def project do
    [ app: :calliope,
      version: "0.2.1",
      elixir: ">= 0.13.3",
      deps: [],
      package: [
        files: ["lib", "mix.exs", "README*", "LICENSE*"],
        contributors: ["Johnny Winn"],
        licenses: ["Apache 2.0"],
        links: [ github: "https://github.com/nurugger07/calliope" ] 
      ],
      description: """
      An Elixir library for parsing haml templates.
      """
    ]
  end
end
