defmodule KeyMaps.Mixfile do
  use Mix.Project

  def project do
    [app: :key_maps,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :cowboy,
        :ecto,
        :ectograph,
        :guardian,
        :httpoison,
        :logger,
        :plug,
        :plug_graphql,
        :postgrex
      ],
      mod: {
        KeyMaps,
        []
      },
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      { :corsica, "~> 0.5.0" },
      { :cowboy, "~> 1.0.4" },
      { :ecto, "~> 2.0.4" },
      { :ectograph, "~> 0.2.0" },
      { :graphql, "~> 0.3.1" },
      { :guardian, "~> 0.12.0" },
      { :httpoison, "~> 0.9.0" },
      { :plug, "~> 1.2.0", override: true },
      { :plug_graphql, "~> 0.3.1" },
      { :postgrex, "~> 0.11.2" }
    ]
  end
end
