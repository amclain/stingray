import Config

config :stingray, data_directory: "/data"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

# Use shoehorn to start the main application. See the shoehorn
# library documentation for more control in ordering how OTP
# applications are started and handling failures.

config :shoehorn, init: [:nerves_runtime, :nerves_pack]

# Erlinit can be configured without a rootfs_overlay. See
# https://github.com/nerves-project/erlinit/ for more information on
# configuring erlinit.

config :nerves,
  erlinit: [
    hostname_pattern: "stingray-%s"
  ]

# Configure the device for SSH IEx prompt access and firmware updates
#
# * See https://hexdocs.pm/nerves_ssh/readme.html for general SSH configuration
# * See https://hexdocs.pm/ssh_subsystem_fwup/readme.html for firmware updates

keys =
  case System.get_env("SSH_GITHUB_USERS") do
    nil ->
      # Use a key on the local machine if it exists.

      [
        Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
        Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
        Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
      ]
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(&File.read!/1)

    github_users_string ->
      # Use public SSH keys from GitHub.

      users = String.split(github_users_string)

      Enum.reduce(users, [], fn user, keys ->
        keys ++
        case System.cmd("curl", ["-s", "-f", "https://github.com/#{user}.keys"]) do
          {response, 0} ->
            response
            |> String.split("\n")
            |> Enum.filter(& &1 != "")

          {_, _} ->
            Mix.raise "Failed to get SSH keys from GitHub for user `#{user}`"
        end
      end)
  end
  
if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config/target.exs for this error message.
    """)

config :nerves_ssh, authorized_keys: keys

# Configure the network using vintage_net
# See https://github.com/nerves-networking/vintage_net for more information
config :vintage_net,
  regulatory_domain: "US",
  config: [
    {"usb0", %{type: VintageNetDirect}},
    {"eth0",
     %{
       type: VintageNetEthernet,
       ipv4: %{method: :dhcp}
     }},
    {"wlan0", %{type: VintageNetWiFi}}
  ]

config :mdns_lite,
  # The `hosts` key specifies what hostnames mdns_lite advertises.  `:hostname`
  # advertises the device's hostname.local. For the official Nerves systems, this
  # is "nerves-<4 digit serial#>.local".  The `"nerves"` host causes mdns_lite
  # to advertise "nerves.local" for convenience. If more than one Nerves device
  # is on the network, it is recommended to delete "nerves" from the list
  # because otherwise any of the devices may respond to nerves.local leading to
  # unpredictable behavior.

  hosts: [:hostname, "stingray"],
  ttl: 120,

  # Advertise the following services over mDNS.
  services: [
    %{
      protocol: "ssh",
      transport: "tcp",
      port: 22
    },
  ]
