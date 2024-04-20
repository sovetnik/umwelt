defmodule Umwelt.MixProject do
  use Mix.Project

  def project do
    [
      app: :umwelt,
      version: "0.1.0",
      elixir: "~> 1.15",
      compilers: [:leex, :yecc] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "Umwelt",
      description: "Umwelt is an Elixir parser for umwelt.dev",
      package: [licenses: ["Apache-2.0"]],
      homepage_url: "https://umwelt.dev/",
      source_url: "https://github.com/sovetnik/umwelt"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
