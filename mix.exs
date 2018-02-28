defmodule Wicket.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wicket,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :httpoison],
      mod: {Wicket, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:slack, "~> 0.12.0"},
      {:cowboy, "~> 1.0.0"},
      {:httpoison, "~> 0.11"}
    ]
  end
end
