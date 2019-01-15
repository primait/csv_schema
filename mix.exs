defmodule Csv.Schema.MixProject do
  use Mix.Project

  def project do
    [
      app: :csv_schema,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: ["lib"],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
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

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:csv, "~> 2.1"},
      {:timex, "~> 3.1"},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "A library to build in-code schema starting from csv files"
  end

  defp package do
    [
      maintainers: ["Simone Cottini"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/primait/csv_schema"}
    ]
  end
end
