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
      test_coverage: [tool: ExCoveralls, test_task: "espec"],
      dialyzer: [
        ignore_warnings: "dialyzer.ignore.exs",
        list_unused_filters: true,
        plt_add_apps: [:mix],
        plt_file: {:no_warn, plt_file_path()},
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.show": :test,
        espec: :test,
      ],
      preferred_cli_target: [
        dialyzer: :bbb,
        run: :host,
        test: :host,
      ],
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
      "coveralls.show": ["coveralls.html", &open("cover/excoveralls.html", &1)],
      "docs.show": ["docs", &open("doc/index.html", &1)],
      test: "coveralls",
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:circuits_gpio, "~> 1.0"},
      {:cubdb, "~> 2.0"},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false},
      {:espec, "~> 1.9", only: :test},
      {:excoveralls, "~> 0.15", only: :test},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:file_system, "~> 0.2.10"},
      {:jason, "~> 1.4"},
      {:nerves, "~> 1.10", runtime: false},
      {:shoehorn, "~> 0.9"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},
      {:muontrap, "~> 1.1"},
      {:resolve, "~> 0.1"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.13", targets: @all_targets},
      {:nerves_pack, "~> 0.7", targets: @all_targets},

      # Dependencies for specific targets
      stingray_nerves_system(),
    ]
  end

  defp stingray_nerves_system do
    path = System.get_env("STINGRAY_SYSTEM_PATH", "")

    case File.exists?(path) do
      true -> {
        :nerves_system_stingray_bbb,
        path: path,
        runtime: false,
        targets: :bbb
      }

      _ -> {
        :nerves_system_stingray_bbb,
        ref: "v1.0.4",
        git: "git@github.com:amclain/nerves_system_stringray_bbb.git",
        runtime: false,
        targets: :bbb
      }
    end
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

  # Path to the dialyzer .plt file.
  defp plt_file_path do
    [Mix.Project.build_path(), "plt", "dialyxir.plt"]
    |> Path.join()
    |> Path.expand()
  end

  # Open a file with the default application for its type.
  defp open(file, _args) do
    open_command =
      System.find_executable("xdg-open") # Linux
      || System.find_executable("open")  # Mac
      || raise "Could not find executable 'open' or 'xdg-open'"

    System.cmd(open_command, [file])
  end
end
