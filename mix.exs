defmodule DoubleBypass.Mixfile do
  use Mix.Project

  def project do
    [app: :double_bypass,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:bypass, :logger]]
  end

  defp deps do
    [
      {:bypass, "~> 0.5"},
      {:poison, "~> 2.0"}
    ]
  end
end
