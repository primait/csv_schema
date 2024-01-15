defmodule Csv.Schema.MixProject do
  use Mix.Project

  @source_url "https://github.com/primait/csv_schema"
  @version "1.1.0-rc.0"

  def project do
    [
      app: :csv_schema,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixir_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :app_tree,
        ignore_warnings: ".dialyzerignore"
      ]
    ]
  end

  def elixir_paths(env) when env in [:dev, :test], do: ["lib", "benchmark"]
  def elixir_paths(_), do: ["lib"]

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:csv, "~> 3.2"},
      {:timex, "~> 3.7"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "1.4.3", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "format.check": [
        "format --check-formatted mix.exs 'lib/**/*.{ex,exs}' 'test/**/*.{ex,exs}' 'config/*.{ex, exs}'"
      ],
      check: ["format.check", "credo -a", "dialyzer"]
    ]
  end

  defp package do
    [
      description: "A library to build in-code schema starting from csv files",
      maintainers: ["Simone Cottini"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
