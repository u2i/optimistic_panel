defmodule OptimisticPanel.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :optimistic_panel,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "OptimisticPanel",
      source_url: "https://github.com/your-username/optimistic_panel"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_view, "~> 0.20.0"}
    ]
  end

  defp description do
    """
    Optimistic UI panel components (modal and slideover) for Phoenix LiveView with 
    focus management, accessibility, and smooth animations.
    """
  end

  defp package do
    [
      name: "optimistic_panel",
      files: ~w(lib assets mix.exs README.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-username/optimistic_panel"}
    ]
  end
end
