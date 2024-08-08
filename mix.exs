defmodule Umwelt.MixProject do
  use Mix.Project

  def project do
    [
      app: :umwelt,
      version: "0.2.0",
      elixir: "~> 1.17",
      compilers: [:leex, :yecc] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [plt_add_apps: [:mix]],
      name: "Umwelt",
      description: "Umwelt is an Elixir parser for umwelt.dev",
      package: package(),
      homepage_url: "https://umwelt.dev/",
      source_url: "https://github.com/sovetnik/umwelt"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:inets, :logger, :public_key, :ssl],
      mod: {Umwelt.Client.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:certifi, "~> 2.5"},
      {:jason, "~> 1.2"},
      {:progress_bar, "~> 3.0"},
      {:bypass, "~> 2.1", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/sovetnik/umwelt"}
    ]
  end
end
