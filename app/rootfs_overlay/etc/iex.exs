logo = """
\e[1;34m   ▄██▄          \e[0m
\e[1;34m ▄██████▄        \e[0m
\e[1;34m███8██████======>\e[0m  \e[1;36mS T I N G R A Y\e[0m
\e[1;34m ▀██████▀        \e[0m
\e[1;34m   ▀██▀          \e[0m
"""

IEx.configure(default_prompt: "%prefix(%counter)\e[1;34m=>\e[0m")
IEx.configure(alive_prompt: "%prefix(%node)%counter\e[1;34m=>\e[0m")

NervesMOTD.print(logo: logo)

# Add Toolshed helpers to the IEx session
use Toolshed

alias Stingray.Target
