defmodule Csv.Schema.MixProject do
  use Mix.Project

  def project do
    [
      app: :csv_schema,
      version: "1.0.0",
      elixir: "~> 1.6",
      elixirc_paths: elixir_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      package: package(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :transitive,
        ignore_warnings: ".dialyzerignore"
      ],
      docs: [main: Csv.Schema]
    ]
  end

  def elixir_paths(env) when env in [:dev, :test], do: ["lib", "benchmark"]
  def elixir_paths(_), do: ["lib"]

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:csv, "~> 2.1"},
      {:timex, "~> 3.1"},
      {:credo, "~> 1.2", only: [:dev, :test]},
      {:dialyxir, "1.0.0-rc.7", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "A library to build in-code schema starting from csv files"
  end

  defp aliases do
    [
      "format.check": ["format --check-formatted mix.exs 'lib/**/*.{ex,exs}' 'test/**/*.{ex,exs}' 'config/*.{ex, exs}'"],
      check: ["format.check", "credo -a", "dialyzer"]
    ]
  end

  defp package do
    [
      maintainers: ["Simone Cottini"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/primait/csv_schema"}
    ]
  end
end
