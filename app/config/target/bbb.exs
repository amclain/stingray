import Config

config :resolve,
  compile: true,
  mappings: [
    {Stingray.PowerManager, Stingray.PowerManager.Driver},
  ]

config :stingray, io: %{
  relay_pin: 48,
}
