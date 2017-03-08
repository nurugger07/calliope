Code.ensure_loaded?(Hex) and Hex.start

defmodule Calliope.Mixfile do
  use Mix.Project

  def project do
    [ app: :calliope,
      version: "0.4.1",
      elixir: "~> 1.4",
      deps: [],
      package: [
        files: ["lib", "mix.exs", "README*", "LICENSE*"],
        contributors: ["Johnny Winn", "Stephen Pallen"],
        maintainers: ["Johnny Winn", "Stephen Pallen"],
        licenses: ["Apache 2.0"],
        links: %{ "Github" => "https://github.com/nurugger07/calliope" }
      ],
      description: """
      An Elixir library for parsing haml templates.
      """
    ]
  end
end
