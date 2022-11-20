# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Configuration overlay order.
#
# 1. config/config.exs
# 2. config/target/non_host.exs
# 3. config/target/#{Mix.target()}.exs
# 4. config/env/#{Mix.env()}.exs

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :stingray, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1667776425"

if Mix.target() != :host do
  import_config "target.exs"
end

import_config "target/#{Mix.target()}.exs"
import_config "env/#{Mix.env()}.exs"
