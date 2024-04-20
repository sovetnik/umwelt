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
      description: description(),
      package: package(),
      name: "Umwelt",
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

  defp description do
    "Umwelt is an Elixir parser for umwelt.dev"
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "Umwelt.dev" => "https://umwelt.dev/",
        "GitHub" => "https://github.com/sovetnik/umwelt"
      }
    ]
  end
end
