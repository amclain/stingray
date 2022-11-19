defmodule Stingray.MixProject do
  use Mix.Project

  @app :stingray
  @version "0.1.0"
  @all_targets [:bbb]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.14",
      archives: [nerves_bootstrap: "~> 1.11"],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Stingray.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp aliases do
    [
      "docs.show": ["docs", &docs_open/1]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:nerves, "~> 1.9", runtime: false},
      {:shoehorn, "~> 0.9"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},
      {:muontrap, "~> 1.1"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.13", targets: @all_targets},
      {:nerves_pack, "~> 0.7", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_stingray_bbb, path: "../nerves_system_stingray_bbb", runtime: false, targets: :bbb}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["../README.md", "../LICENSE.txt"]
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  defp docs_open(_args) do
    System.cmd(open_command(), ["doc/index.html"])
  end

  defp open_command() do
    System.find_executable("xdg-open") # Linux
    || System.find_executable("open")  # Mac
    || raise "Could not find executable 'open' or 'xdg-open'"
  end
end
