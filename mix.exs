defmodule DoubleBypass.Mixfile do
  use Mix.Project

  def project do
    [
      app: :double_bypass,
      version: "0.0.6",
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [applications: [:bypass, :logger]]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 1.0"},
      {:bypass, "~> 1.0"},
      {:credo, "~> 1.4", only: :dev},
      {:ex_doc, "~> 0.22.1", only: :dev},
      {:excoveralls, "~> 0.13", only: :test},
      {:httpoison, "~> 1.7", only: :test},
      {:jason, "~> 1.2"}
    ]
  end

  defp description do
    """
    A wrapper around Bypass. Double Bypass makes configuring and initializing Bypass easy.
    It also removes redundant test assertion code, and ecourages testing external requests in
    a self documenting manner.
    """
  end

  defp package do
    [
      name: :double_bypass,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Michael Smykowski"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/msmykowski/double_bypass"}
    ]
  end
end
