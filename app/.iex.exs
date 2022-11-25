IEx.configure(default_prompt: "%prefix(%counter)\e[1;34m=>\e[0m")
IEx.configure(alive_prompt: "%prefix(%node)%counter\e[1;34m=>\e[0m")

import Stingray, only: [console: 1]

alias Stingray.Target
