# NixOS x Proxmox infra configuration with Terranix

This repository allows to manage LXC containers on Proxmox.

It's supposed to be used from an host where `nixos-rebuild` is available.

  - Uses `nix-community/generators` to build a LXC template with a base NixOS container
  - Uses `terranix` to build the infra definition and `opentofu` to deploy it on Proxmox
  - Uses `nixos-rebuild` to deploy the configuration on the container
  - Uses `agenix` to avoid having too many secrets in clear

My main objective was to have a "light" definition for the containers and to be able to use Nix to factorize configuration.

Sadly as there is quite a bit of self/cross-references, I "had" to frequently split the configs in two definitions (which pretty much defeats my initial purpose).

# Architecture

- `config/_globals.nix` => Global values used in a lot of places
- `config/_ids.nix` => hostname -> container ID mapping
- `config/_keys.nix` => hostname -> public ssh key mapping (for secrets, built with ssh-keyscan {ip})
- `config/_passwords.nix` => hostname -> db password...
- `containers/{name}.nix` => main definition of the container with my custom module
- `modules/containers.nix` => container module definition & evaluation
- `modules/tools.nix` => some utilities using global config etc. Also the main logic to convert a container ID to an IP
- `config/{name}-*.nix` => additional configuration if needed, imported with the whole config available for cross-references.
- `secrets/` => Agenix secrets

# My Stack

- DNS: AdGuardHome with Unbound
- Reverse Proxy: Traefik
- Auth: Authentik - mostly manual for now, I'd like to add Terraform...
- DB: Postgres
- Monitoring: Prometheus + Loki + Grafana and Alloy agents on hosts

# Setting up

1. Build your `config/_globals.nix` using the example
2. Fill in `config/_ids.nix` - probably starting with your existing and relevant hosts/IP
3. Adapt `modules/tools.nix` to be relevant with your setup
4. Adapt `modules/lxc-template.nix` as needed
5. Run `build-template` (= `nix build .#lxc-template -o nixos-template`) to build the Proxmox LXC template.
6. Upload the template to Proxmox (TODO Try to automate this)
7. Create a user/role etc on Proxmox (see [the provider documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs))
8. Create `terraform.tfvars` and adapt it with the relevant infos
9. Run `tofu init`

Probably remove all files in `containers/` that you don't need, or move them to another folder. Another option is to set `my-lxc.[name].container.enable = false;`.

Also it is tailored for my use and was built iteratively so I guess if you want to replicate my setup you'll have to disable things to make it work and iteratively add them back. First I'd disable `logging.enable` in every `my-lxc` module.

# Adding a container

To add a container, the main workflow is:
- run `add-lxc {name} {id}`
- edit `containers/{name}.nix`
  - adapt container specs
  - setup NixOS config
  - setup DB if needed
  - enable logging, routing, auth, ...
- if needed, add additional definition in `config/{name}-{service}.nix` and reference it in `containers/{name}.nix`
- add needed secrets in `secrets/secrets.nix` and use `cd secrets && agenix -e {secret-name}.age` to create the encrypted files (see agenix doc)
- run `build-terraform-json` to build the Terraform definition
- run `tofu apply`, REVIEW the plan, and confirm if it's OK
- start the container on Proxmox (probably should add the option in terraform but I prefer to have control...)
- run `ssh-keyscan {ip}` and add the public SSH key to `config/_keys.nix` for the secrets decoding - run `cd secrets && agenix -r` to re-build the secrets for your new key
- run `deploy-lxc {name}` to deploy the NixOS setup to Proxmox
- if needed, run `deploy-lxc {proxy}` to enable routing to your new container

