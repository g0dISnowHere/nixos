This is a work in progress, there are a lot of things left to do.

# Purpose of this config/PC
Provide some services on my local network.
## homeassistant
- enable virtualisation -> VM
- other setup?
## octoprint
- docker
- behind reverse proxy?
## reverse proxy for services on my LAN -> SSL!!
- use it for locally installed services
- use it for other services
- is a fallback necessary/helpfull?

# things that are left to do
- backup strategy
- sync strategy for the nix config

# Things that didn't initially go well
- importing the flake:
    - git had to be initialized
    - the existing tree wasn't recognized
- logged out everywhere
- secrets

## Improvements
- pull directly from an existing git repo
- nixos-rebuild on [another machine](https://nixos.wiki/wiki/Distributed_build)