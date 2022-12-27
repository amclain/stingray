import Config

# Add configuration that is only needed when running on the host here.

config :stingray,
  data_directory: "./data",
  enable_nfs: false

config :stingray, di: %{
  compile: false,
  mappings: [
    {Stingray.PowerManager, Stingray.PowerManager.Virtual},
  ]
}

config :stingray, io: %{
  relay_pin: -1,
}
