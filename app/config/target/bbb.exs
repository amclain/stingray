import Config

config :stingray, di: %{
  compile: true,
  mappings: [
    {Stingray.PowerManager, Stingray.PowerManager.Driver},
  ]
}

config :stingray, io: %{
  relay_pin: 48,
}
